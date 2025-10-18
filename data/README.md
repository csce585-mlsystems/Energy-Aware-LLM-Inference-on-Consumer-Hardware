# Data Directory Overview

This folder stores prompt corpora, telemetry logs, and derived metrics referenced throughout Milestone P1.

## Prompts
- `prompts/sd.jsonl` — Short dialogue prompts curated from LMSYS-Chat-1M samples.
- `prompts/ar.jsonl` — Analytical reasoning prompts derived from GSM8K style questions.
- `prompts/ng.jsonl` — Narrative generation prompts adapted from the WritingPrompts dataset.
- `prompts/manual_prompts.json` — Legacy manual prompt list retained for backward compatibility with `run_cpu.py`/`run_gpu.py`.

Each JSONL entry includes an `id`, natural-language `text`, and a `template` tag for grouping during analysis.

## Telemetry Logs
- `measurements/p1/<backend>/<suite>/run_metrics.csv` — Summaries of three trials per backend and prompt suite.
- `power_logs.csv` — Aggregate power samples recorded via `TelemetryLogger`.
- `latency_results.csv` — Prompt-level latency entries recorded via `TelemetryLogger`.

Raw Intel Power Gadget exports are archived alongside the main power log as `raw_cpu_power_*.csv`. GPU power logs should be stored in `measurements/p1/gpu/` with consistent naming.

## Models
- The `models/` subdirectory is intentionally empty in version control. Place TinyLlama GGUF artifacts here and verify their checksums against `config/model_hashes.json` before running experiments.

## Derived Artifacts
- `doc/p1_metrics_summary.csv` — Generated via `uv run python src/analysis/p1_summary.py`.
- `doc/figures/p1_energy_per_token.html` — Interactive visualization of energy-per-token comparisons.

Please avoid committing proprietary datasets or large telemetry exports to the repository. Compress artifacts exceeding 25 MB before uploading to the course LMS.
