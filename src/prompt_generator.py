"""Utilities for synthesizing prompt batches for llama.cpp benchmarks.

This module reads a JSON configuration describing prompt templates and
variable slots, then renders a prompt collection that can be consumed by
`run_cpu.py` and `run_gpu.py` prior to invoking llama.cpp.  Keeping prompt
creation centralized ensures CPU and GPU runs stay comparable even when
prompt text is generated automatically.
"""
from __future__ import annotations

import json
import itertools
import random
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Sequence


@dataclass
class Prompt:
    """Simple value object describing a prompt payload."""

    id: str
    text: str
    template: str

    @property
    def length_chars(self) -> int:
        return len(self.text)


class PromptConfigError(RuntimeError):
    """Raised when the prompt configuration file is invalid."""


def _load_config(config_path: Path) -> Dict:
    try:
        with config_path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except FileNotFoundError as exc:  # pragma: no cover - defensive
        raise PromptConfigError(f"Prompt config not found: {config_path}") from exc
    except json.JSONDecodeError as exc:  # pragma: no cover - defensive
        raise PromptConfigError(
            f"Prompt config contains invalid JSON: {config_path}"
        ) from exc


def _load_template_text(template_dir: Path, entry: Dict[str, str]) -> str:
    template_file = template_dir / entry["file"]
    try:
        return template_file.read_text(encoding="utf-8")
    except FileNotFoundError as exc:  # pragma: no cover - defensive
        raise PromptConfigError(
            f"Template file '{template_file}' referenced in config but not found"
        ) from exc


def _variable_product(variables: Dict[str, Sequence[str]]) -> Iterable[Dict[str, str]]:
    if not variables:
        yield {}
        return

    keys = list(variables.keys())
    value_lists: List[Sequence[str]] = [variables[key] for key in keys]
    for combo in itertools.product(*value_lists):
        yield dict(zip(keys, combo))


def _render_template(template_text: str, slot_values: Dict[str, str]) -> str:
    try:
        return template_text.format(**slot_values)
    except KeyError as exc:  # pragma: no cover - defensive
        missing = exc.args[0]
        raise PromptConfigError(
            f"Template references variable '{missing}' that is not defined in config"
        ) from exc


def generate_prompts(config_path: str) -> List[Prompt]:
    """Render prompts from templates defined in a configuration file.

    Parameters
    ----------
    config_path:
        Path to a JSON file describing prompt templates.  The schema is:

        ```json
        {
          "template_dir": "data/prompt_templates",
          "random_seed": 123,
          "templates": [
            {
              "name": "analysis",
              "file": "analysis.txt",
              "count": 3,
              "variables": {
                "topic": ["renewable energy", "chip design"],
                "tone": ["technical", "executive"]
              }
            }
          ]
        }
        ```

    Returns
    -------
    List[Prompt]
        A collection of prompts ready to execute.
    """

    config = _load_config(Path(config_path))
    template_dir = Path(config.get("template_dir", "data/prompt_templates"))
    rng = random.Random(config.get("random_seed"))
    prompts: List[Prompt] = []

    templates = config.get("templates", [])
    if not templates:
        raise PromptConfigError("Prompt config must define at least one template entry")

    for entry in templates:
        name = entry.get("name")
        if not name:
            raise PromptConfigError("Each template entry requires a 'name'")

        template_text = _load_template_text(template_dir, entry)
        count = int(entry.get("count", 1))
        variables: Dict[str, Sequence[str]] = entry.get("variables", {})

        # If there are enough Cartesian combinations to cover `count`, sample without
        # replacement. Otherwise shuffle the rendered prompts and wrap around.
        rendered_variations = [
            _render_template(template_text, slot_values)
            for slot_values in _variable_product(variables)
        ]
        if not rendered_variations:
            rendered_variations = [_render_template(template_text, {})]

        if count <= len(rendered_variations):
            selected_texts = rng.sample(rendered_variations, k=count)
        else:
            expanded = rendered_variations * (count // len(rendered_variations) + 1)
            rng.shuffle(expanded)
            selected_texts = expanded[:count]

        for index, text in enumerate(selected_texts, start=1):
            prompt_id = f"{name}-{index:03d}-{uuid.uuid4().hex[:8]}"
            prompts.append(Prompt(id=prompt_id, text=text.strip(), template=name))

    return prompts


__all__ = ["Prompt", "PromptConfigError", "generate_prompts"]
