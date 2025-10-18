"""Batch orchestrator for Milestone P1 experiment runs."""
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Optional

import yaml

from telemetry import TelemetryLogger
from workload import configure_prompts, run_prompts


@dataclass
class RunSpec:
    """Concrete parameters resolved from the YAML configuration."""

    run_id: str
    suite: str
    backend: str
    llama_binary: Path
    model_path: Path
    prompt_source: str
    prompt_file: Path
    prompt_config: Path
    batch_size: int
    n_predict: int
    temperature: float
    gpu_layers: Optional[int]
    extra_args: List[str]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--config",
        type=Path,
        default=Path("config/p1_runs.yaml"),
        help="Path to the YAML configuration describing experiment runs.",
    )
    parser.add_argument(
        "--suite",
        action="append",
        dest="suites",
        help="Optional suite filter (can be passed multiple times).",
    )
    parser.add_argument(
        "--backend",
        action="append",
        dest="backends",
        choices=["cpu", "gpu"],
        help="Optional backend filter (cpu/gpu).",
    )
    parser.add_argument(
        "--run-id",
        action="append",
        dest="run_ids",
        help="Execute only runs with the specified identifier (can repeat).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Skip llama.cpp invocation; useful for CI validation.",
    )
    return parser.parse_args()


def load_config(path: Path) -> List[RunSpec]:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not data or "runs" not in data:
        raise ValueError(f"Configuration file {path} must define a top-level 'runs' list")

    defaults = data.get("defaults", {})
    runs: List[RunSpec] = []

    for entry in data["runs"]:
        run_id = entry.get("id") or f"run-{len(runs)+1:02d}"
        suite = entry.get("suite")
        backend = entry.get("backend")
        if not suite or not backend:
            raise ValueError(f"Run {run_id} must specify both 'suite' and 'backend'")

        llama_binary = Path(entry.get("llama_binary") or defaults.get("llama_binary", "llama.cpp/llama-cli"))
        model_path = Path(entry.get("model") or defaults.get("model"))
        if model_path is None:
            raise ValueError(f"Run {run_id} missing 'model' path")

        prompt_source = entry.get("prompt_source") or defaults.get("prompt_source", "manual")
        prompt_file = Path(entry.get("prompt_file") or defaults.get("prompt_file", "data/prompts/manual_prompts.json"))
        prompt_config = Path(entry.get("prompt_config") or defaults.get("prompt_config", "config/prompt_config.json"))

        batch_size = int(entry.get("batch_size") or defaults.get("batch_size", 1))
        n_predict = int(entry.get("n_predict") or defaults.get("n_predict", 128))
        temperature = float(entry.get("temperature") or defaults.get("temperature", 0.2))

        gpu_layers = entry.get("gpu_layers") or defaults.get("gpu_layers")
        if gpu_layers is not None:
            gpu_layers = int(gpu_layers)

        extra_args: List[str] = []
        if backend == "gpu" and gpu_layers is not None:
            extra_args.extend(["--gpu-layers", str(gpu_layers)])
        if entry.get("extra_args"):
            if isinstance(entry["extra_args"], list):
                extra_args.extend(str(arg) for arg in entry["extra_args"])
            else:
                raise ValueError(f"extra_args for run {run_id} must be a list")

        runs.append(
            RunSpec(
                run_id=run_id,
                suite=suite,
                backend=backend,
                llama_binary=llama_binary,
                model_path=model_path,
                prompt_source=prompt_source,
                prompt_file=prompt_file,
                prompt_config=prompt_config,
                batch_size=batch_size,
                n_predict=n_predict,
                temperature=temperature,
                gpu_layers=gpu_layers,
                extra_args=extra_args,
            )
        )
    return runs


def filter_runs(runs: Iterable[RunSpec], args: argparse.Namespace) -> List[RunSpec]:
    selected: List[RunSpec] = []
    allowed_ids = set(args.run_ids or [])
    allowed_suites = set(args.suites or [])
    allowed_backends = set(args.backends or [])

    for run in runs:
        if allowed_ids and run.run_id not in allowed_ids:
            continue
        if allowed_suites and run.suite not in allowed_suites:
            continue
        if allowed_backends and run.backend not in allowed_backends:
            continue
        selected.append(run)
    return selected


def execute_runs(runs: Iterable[RunSpec], dry_run: bool = False) -> None:
    logger = TelemetryLogger()
    for spec in runs:
        print(f"\n=== Running {spec.run_id} ({spec.suite}, {spec.backend}) ===")
        prompts = configure_prompts(spec.prompt_source, spec.prompt_file, spec.prompt_config)

        run_prompts(
            prompts=prompts,
            llama_binary=spec.llama_binary,
            model_path=spec.model_path,
            backend=spec.backend,
            logger=logger,
            batch_size=spec.batch_size,
            n_predict=spec.n_predict,
            temperature=spec.temperature,
            dry_run=dry_run,
            extra_args=spec.extra_args,
        )

        print(f"✅ Completed {spec.run_id}")


def main() -> None:
    args = parse_args()
    config_path = args.config
    runs = load_config(config_path)
    filtered = filter_runs(runs, args)
    if not filtered:
        raise SystemExit("No runs selected. Adjust your filters or configuration file.")

    execute_runs(filtered, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
