# Energy-Aware LLM Inference on Consumer Hardware

## Group Info
- Suprawee Pongpeeradech  
  Email: [suprawee@email.sc.edu](mailto:suprawee@email.sc.edu)

## Project Summary/Abstract
Large language models enable rich conversational applications but impose heavy energy costs when deployed on commodity desktops. This project benchmarks TinyLlama-1.1B inference on an Intel Core i5-13600K CPU and an NVIDIA RTX 3060 GPU, measuring latency, throughput, and joules per generated token across representative prompt suites. The resulting guidance helps students and small labs decide when CPU-only execution is preferable and when GPU acceleration justifies its higher power draw.

## Problem Description
- **Problem:** CPU and GPU backends expose different trade-offs for interactive TinyLlama workloads. Practitioners lack reproducible data that ties prompt length, batch size, and quantization to energy efficiency.
- **Motivation:** Consumer deployments often operate under thermal or cost constraints. Understanding energy-delay trade-offs enables better scheduling and hardware purchasing decisions.
- **Challenges:**
  - Capturing synchronized telemetry from Intel Power Gadget and NVIDIA NVML under Windows/WSL2.
  - Designing prompt suites that exercise short-form, analytical, and narrative workloads.
  - Ensuring reproducible experiment orchestration with clear configuration and logging.

## Contribution
- Implemented a unified runner (`src/run_session.py`) that loads YAML experiment manifests and executes CPU/GPU trials with consistent telemetry logging.
- Curated prompt suites for short dialogue, analytical reasoning, and narrative generation stored in `data/prompts/*.jsonl`.
- Produced Milestone P1 results comparing energy per token, latency, and energy-delay product for CPU vs. GPU pipelines, with plots generated via `src/analysis/p1_summary.py`.

## Milestone P1 Reproduction
Follow these steps on a workstation with both CPU and NVIDIA GPU access.

### 1. Prerequisites
- Windows 11 Pro 23H2 with WSL2 (Ubuntu 22.04) enabled.
- Intel Power Gadget 3.7.0 (for CPU energy telemetry).
- NVIDIA drivers with NVML support.
- CMake and a C++17 toolchain (Visual Studio Build Tools 2022 recommended).
- `uv` package manager (https://docs.astral.sh/uv/).

### 2. Clone repositories
```powershell
# PowerShell (host)
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
cmake -S . -B build -DLLAMA_CUBLAS=ON -DLLAMA_NATIVE=ON
cmake --build build --config Release

cd ..
git clone https://github.com/csce585-mlsystems/Energy-Aware-LLM-Inference-on-Consumer-Hardware.git
```

### 3. Provision Python environment (inside WSL2)
```bash
cd Energy-Aware-LLM-Inference-on-Consumer-Hardware
uv sync  # uses pyproject.toml and uv.lock
```
> If dependency resolution fails due to offline environments, rerun `uv lock` once connectivity is restored to refresh `uv.lock`.

### 4. Acquire models and datasets
- Download `TinyLlama-1.1B-Chat-v1.0.Q4_0.gguf` (and optional Q5_1 variant) and place them in `data/models/`.
- Verify checksums with:
  ```bash
  python - <<'PY'
  import hashlib, json
  from pathlib import Path

  config = json.loads(Path('config/model_hashes.json').read_text())
  for name, meta in config.items():
      path = Path('data/models') / name
      if path.exists():
          digest = hashlib.sha256(path.read_bytes()).hexdigest()
          print(f"{name}: {digest == meta['sha256']}")
      else:
          print(f"{name}: missing")
  PY
  ```
- Prompt suites already live in `data/prompts/sd.jsonl`, `ar.jsonl`, and `ng.jsonl`.

### 5. Run experiments
```bash
# Run full session (CPU & GPU for all suites)
uv run python src/run_session.py
```
Logs are appended to `data/latency_results.csv` and `data/power_logs.csv`. Raw high-frequency power logs are saved in `data/` as `raw_cpu_power_*.csv` and `raw_gpu_power_*.csv`.

### 6. Summarize results
```bash
uv run python src/analysis/generate_report.py
```
This command parses the latest logs and generates a summary table in `doc/latest_report.md`.
You can also run the Jupyter notebook `src/analysis/p1_energy_latency.ipynb` for interactive visualization.

### 7. Prepare submission artifacts
- Export `doc/Milestone P1 — Initial Experiment and Evaluation Setup.md` to PDF.
- Build slides from `doc/p1_slides_outline.md`.

## Directory Layout
```
|- config/
|  |- model_hashes.json
|  |- p1_runs.yaml
|- data/
|  |- latency_results.csv
|  |- power_logs.csv
|  |- models/
|  |- prompts/
|- doc/
|  |- Milestone P0 — Project Proposal and Motivation.md
|  |- Milestone P1 — Initial Experiment and Evaluation Setup.md
|  |- latest_report.md
|- src/
|  |- analysis/
|  |  |- generate_report.py
|  |  |- p1_energy_latency.ipynb
|  |- run_session.py
|  |- telemetry.py
|  |- workload.py
|- pyproject.toml
|- uv.lock
```

## Data & Telemetry Notes
- `TelemetryLogger` writes prompt-level latency and power data to CSV files that can be ingested by pandas or Polars.
- Synthetic sample metrics for Milestone P1 are stored in `data/measurements/p1/**/run_metrics.csv` to demonstrate the aggregation pipeline. Replace them with fresh measurements when rerunning the study.
- Use `src/utils/sync_logs.py` to align CPU and GPU power samples before computing combined Energy-Delay Product figures.

## References
1. Gerganov, G. *llama.cpp*. GitHub. https://github.com/ggerganov/llama.cpp
2. Intel Corporation. *Intel Power Gadget User Guide*, 2024.
3. NVIDIA Corporation. *NVIDIA Management Library (NVML) API Reference Manual*, 2024.
