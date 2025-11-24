# Energy-Aware LLM Inference on Consumer Hardware

**Course:** CSCE 585 — Machine Learning Systems  
**Status:** Milestone P1 Complete (Initial Experiment & Evaluation Setup)

## Group Info
- Suprawee Pongpeeradech  
  Email: [suprawee@email.sc.edu](mailto:suprawee@email.sc.edu)

## Project Summary
Large language models enable rich conversational applications but impose heavy energy costs when deployed on commodity desktops. This project benchmarks **TinyLlama-1.1B** inference on an Intel Core i5-13600K CPU and an NVIDIA RTX 3060 GPU. We measure **latency**, **energy (Joules)**, and **Energy-Delay Product (EDP)** to guide hardware and scheduling decisions.

## Key Findings (Milestone P1)
- **Baseline Established:** We have successfully instrumented a consumer PC to capture synchronized power telemetry from both CPU (Intel Power Gadget) and GPU (NVML).
- **Initial Comparison:** Preliminary results show a significant efficiency advantage for GPU inference, with lower latency and reduced energy-per-token compared to the CPU baseline.
- **Pipeline Verified:** The automated runner (`src/run_session.py`) correctly orchestrates experiments, ensuring reproducibility.

---

## Reproduction Steps

### 1. Prerequisites
- **OS:** Windows 10/11 (Native or WSL2).
- **Hardware:** Intel CPU + NVIDIA GPU (optional but recommended).
- **Software:**
  - Python 3.11+
  - `uv` package manager (https://docs.astral.sh/uv/)
  - `llama.cpp` (compiled with CUBLAS support)
  - Intel Power Gadget (for CPU telemetry)

### 2. Setup
```powershell
# 1. Clone repo
git clone https://github.com/csce585-mlsystems/Energy-Aware-LLM-Inference-on-Consumer-Hardware.git
cd Energy-Aware-LLM-Inference-on-Consumer-Hardware

# 2. Install dependencies
uv sync

# 3. Download Model
uv run download_model.py
```

### 3. Run Experiments
We use `src/run_session.py` to orchestrate experiments defined in YAML config files.

#### Phase 1: Baseline Comparison (CPU vs GPU)
```powershell
uv run python src/run_session.py --config config/p1_runs.yaml
```

### 4. Generate Analysis & Report
This script parses the telemetry logs (`data/latency_results.csv`, `data/power_logs.csv`), generates plots in `doc/figures/`, and creates a summary report.

```powershell
uv run python src/analysis/generate_report.py
```

**Output:**
- **Report:** `doc/latest_report.md`
- **Figures:**
  - `doc/figures/energy_vs_latency.png`
  - `doc/figures/metrics_comparison.png`
  - `doc/figures/gpu_power_trace.png`

---

## Directory Structure
```
├── config/
│   ├── p1_runs.yaml        # Baseline experiment config
├── data/
│   ├── models/             # GGUF models (ignored by git)
│   ├── prompts/            # JSONL prompt files
│   ├── latency_results.csv # Main telemetry log
│   ├── power_logs.csv      # Power summary log
├── doc/
│   ├── figures/            # Generated plots
│   ├── Milestone P1...md   # Initial Report
├── src/
│   ├── analysis/           # Analysis scripts
│   ├── run_session.py      # Experiment runner
│   ├── telemetry.py        # Power/Latency logging
│   ├── workload.py         # llama.cpp wrapper
├── download_model.py       # Model downloader
├── pyproject.toml          # Dependencies
└── README.md               # This file
```

## References
1. Gerganov, G. *llama.cpp*. GitHub. https://github.com/ggerganov/llama.cpp
2. Intel Corporation. *Intel Power Gadget User Guide*, 2024.
3. NVIDIA Corporation. *NVIDIA Management Library (NVML)*.
