"""Shared helpers for CPU/GPU benchmark runners."""
from __future__ import annotations

import json
import subprocess
import time
from pathlib import Path
from typing import Iterable, List, Optional

from prompt_generator import Prompt, PromptConfigError, generate_prompts
from telemetry import TelemetryLogger


def load_manual_prompts(path: Path) -> List[Prompt]:
    """Load prompt definitions from a JSON file.

    The JSON can either be a list of strings or a list of objects with
    ``{"id": "...", "text": "...", "template": "..."}``.
    """
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:  # defensive
        raise RuntimeError(f"Prompt file not found: {path}") from exc
    except json.JSONDecodeError as exc:  # defensive
        raise RuntimeError(f"Prompt file contains invalid JSON: {path}") from exc

    prompts: List[Prompt] = []
    for index, entry in enumerate(payload, start=1):
        if isinstance(entry, str):
            prompts.append(Prompt(id=f"manual-{index:03d}", text=entry, template="manual"))
        elif isinstance(entry, dict):
            text = entry.get("text")
            if not text:
                raise RuntimeError("Prompt entries must include a 'text' field")
            prompt_id = entry.get("id") or f"manual-{index:03d}"
            template = entry.get("template", "manual")
            prompts.append(Prompt(id=prompt_id, text=text, template=template))
        else:
            raise RuntimeError("Prompt entries must be strings or objects")
    return prompts


def select_prompts(prompt_source: str, manual_path: Path, config_path: Path) -> List[Prompt]:
    if prompt_source == "manual":
        return load_manual_prompts(manual_path)
    if prompt_source == "auto":
        return generate_prompts(str(config_path))
    raise ValueError(f"Unsupported prompt source: {prompt_source}")


def run_prompts(
    prompts: Iterable[Prompt],
    llama_binary: Path,
    model_path: Path,
    backend: str,
    logger: TelemetryLogger,
    batch_size: int = 1,
    n_predict: int = 128,
    temperature: float = 0.2,
    dry_run: bool = False,
    extra_args: Optional[Iterable[str]] = None,
) -> None:
    """Execute prompts sequentially and capture telemetry."""

    llama_binary = llama_binary.expanduser()
    if not llama_binary.exists() and not dry_run:
        raise FileNotFoundError(
            f"llama.cpp binary not found at '{llama_binary}'. Use --dry-run to skip execution."
        )
    model_path = model_path.expanduser()

    for prompt in prompts:
        start_time = time.perf_counter()
        tokens_generated: Optional[int] = None
        notes = ""

        # --- NEW: record CPU power if running CPU backend ---
        if backend == "cpu" and not dry_run:
            try:
                logger.record_cpu_power(duration=5, notes=f"prompt={prompt.id}")
            except Exception as e:
                print(f"⚠️ CPU power logging failed: {e}")

        if dry_run:
            # Simulate work to allow integration testing without llama.cpp.
            time.sleep(0.05)
            output_text = ""
        else:
            cmd = [
                str(llama_binary),
                "--model",
                str(model_path),
                "--prompt",
                prompt.text,
                "--n-predict",
                str(n_predict),
                "--batch-size",
                str(batch_size),
                "--temp",
                str(temperature),
            ]
            if extra_args:
                cmd.extend(extra_args)

            try:
                result = subprocess.run(
                    cmd,
                    check=True,
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                    errors="ignore"
                )
                output_text = result.stdout.strip()
            except subprocess.CalledProcessError as exc:  # defensive
                output_text = exc.stdout or ""
                notes = f"llama.cpp exited with {exc.returncode}"

        latency_ms = (time.perf_counter() - start_time) * 1000.0
        if output_text:
            tokens_generated = len(output_text.split())

        logger.log_latency(
            backend=backend,
            prompt_id=prompt.id,
            prompt_template=prompt.template,
            prompt_length=prompt.length_chars,
            latency_ms=latency_ms,
            tokens_generated=tokens_generated,
            energy_joules=None,  # GPU will add energy later
            notes=notes,
        )


def configure_prompts(prompt_source: str, manual_path: Path, config_path: Path) -> List[Prompt]:
    try:
        return select_prompts(prompt_source, manual_path, config_path)
    except PromptConfigError as exc:
        raise RuntimeError(str(exc))


__all__ = [
    "configure_prompts",
    "load_manual_prompts",
    "run_prompts",
    "select_prompts",
]
