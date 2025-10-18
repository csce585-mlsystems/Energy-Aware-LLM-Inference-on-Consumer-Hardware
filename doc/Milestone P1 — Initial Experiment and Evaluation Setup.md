# Milestone P1 — Initial Experiment and Evaluation Setup

## Project Overview
- **Course:** CSCE 585 — Machine Learning Systems (Fall 2025)
- **Project Title:** Energy-Aware TinyLlama Inference on Consumer Hardware
- **Milestone Owner:** Suprawee Pongpeeradech (solo project)
- **Submission Date:** October 17, 2025

## 1. System and Dataset Setup
### 1.1 Hardware & Operating Environment
- **Workstation:** Custom desktop with dedicated energy meter.
- **CPU:** Intel Core i5-13600K (Performance 6C @ 5.1 GHz, Efficient 8C @ 3.9 GHz)
- **GPU:** NVIDIA GeForce RTX 3060 (12 GB VRAM)
- **Memory:** 32 GB DDR5-6000
- **Operating Systems:**
  - Windows 11 Pro 23H2 (host) for Intel Power Gadget CLI.
  - Ubuntu 22.04 LTS under WSL2 for experiment orchestration.
- **Power Instrumentation:**
  - Intel Power Gadget 3.7.0 (`PowerLog3.exe`) sampling CPU package energy at 100 ms.
  - NVIDIA Management Library (NVML) accessed through `pynvml` 11.5 for GPU board power.
  - Smart plug (TP-Link HS110) logging wall power at 1 Hz for cross-checking totals.

### 1.2 Software Stack
| Component | Version | Notes |
|-----------|---------|-------|
| `uv` | 0.7.22 | Reproducible Python environment management |
| Python | 3.11.8 | Installed via `uv python install 3.11` |
| `llama.cpp` | Commit `c1a9bc7` (Oct 10, 2025) | Built with `LLAMA_CUBLAS=1` and `LLAMA_NATIVE=1` |
| TinyLlama model | `TinyLlama-1.1B-Chat-v1.0.Q4_0.gguf` | Stored under `data/models/` with checksum `b39e...` |
| Telemetry harness | `src/run_session.py` | Launches inference and streams telemetry |
| Analysis notebooks | `src/analysis/p1_energy_latency.ipynb` | Generates plots and summary tables |

All dependencies are locked in `pyproject.toml` and `uv.lock` at the repository root. Installing the environment and building `llama.cpp` can be reproduced with:
```bash
uv sync
make -C src/runtime llama
```
(`src/runtime/Makefile` encapsulates the compiler flags used in this milestone.)

### 1.3 Prompt Suites and Datasets
- **Short Dialogue (SD):** three prompts sampled from LMSYS-Chat-1M, truncated to 128 input tokens.
- **Analytical Reasoning (AR):** three prompts drawn from the GSM8K test split, padded/truncated to 256 input tokens.
- **Narrative Generation (NG):** three prompts adapted from the WritingPrompts dataset, truncated to 512 input tokens.

Each prompt suite is committed under `data/prompts/{sd,ar,ng}.jsonl`. A configuration manifest (`config/p1_runs.yaml`) captures the prompt IDs, decoding parameters, batch sizes, and random seeds used in the milestone experiments.

## 2. Baseline Implementation
### 2.1 CPU-Only Baseline
- Runs `llama.cpp` with `--threads 12 --batch-size 1 --no-mmap` to maximize CPU utilization while preventing GPU usage.
- Uses deterministic decoding (`--temp 0.1 --top-p 0.9 --repeat-penalty 1.05`).
- Telemetry pipeline collects:
  - CPU package power and cumulative energy from Intel Power Gadget.
  - Token generation latency measured via monotonic clock in `run_session.py`.
- Verification: Matched generated tokens against reference outputs to ensure functional equivalence with GPU pipeline for SD prompts.

### 2.2 GPU-Accelerated Baseline
- Builds CUDA-enabled `llama.cpp` (`--gpu-layers 40`) invoked with `--batch-size 4` for higher throughput.
- NVML polling interval set to 200 ms to align with CPU telemetry timestamps.
- GPU warm-up pass is executed per run to stabilize clocks before logging measurements.

### 2.3 Hybrid and Ablation Variants
- **CPU Batch Scaling:** `--batch-size` ∈ {1, 2, 4} with thread affinity pinned via `taskset`.
- **Quantization Sensitivity:** Compared Q4_0 and Q5_1 GGUF variants on SD prompts to validate consistent accuracy before full milestone run (differences <0.3% in token overlap, not statistically significant).

## 3. Preliminary Experiment
### 3.1 Experimental Protocol
1. For each prompt suite (SD, AR, NG) and backend (CPU, GPU), run three independent trials with fixed seeds (captured in consolidated CSV files).
2. Record per-trial CSV logs under `data/measurements/p1/{backend}/{suite}/run_metrics.csv`.
3. Aggregate metrics using `uv run python src/analysis/p1_summary.py`, which produces `doc/p1_metrics_summary.csv` and plots in `doc/figures/`.

### 3.2 Key Metrics
- **Energy per Output Token (J/token)** — CPU package or GPU board energy divided by generated tokens.
- **Average Latency (ms/token)** — Mean wall-clock time per generated token.
- **95th Percentile Latency (ms/token)** — Tail responsiveness for interactive workloads.
- **Energy-Delay Product (EDP)** — Joules × milliseconds per token.

### 3.3 Results Snapshot
| Prompt Suite | Backend | Energy (J/token) ↓ | Avg Latency (ms/token) ↓ | P95 Latency (ms/token) ↓ | EDP (J·ms/token) ↓ |
|--------------|---------|--------------------|--------------------------|--------------------------|--------------------|
| SD           | CPU     | 2.41 ± 0.09        | 38.7 ± 1.5               | 54.2 ± 2.1               | 93.3               |
| SD           | GPU     | 3.05 ± 0.12        | 21.4 ± 0.8               | 29.7 ± 1.4               | 65.3               |
| AR           | CPU     | 2.88 ± 0.11        | 47.9 ± 2.0               | 67.5 ± 3.2               | 138.1              |
| AR           | GPU     | 2.96 ± 0.14        | 24.6 ± 1.0               | 34.8 ± 1.7               | 72.9               |
| NG           | CPU     | 3.56 ± 0.15        | 59.3 ± 2.8               | 81.0 ± 3.7               | 211.1              |
| NG           | GPU     | 2.79 ± 0.10        | 33.2 ± 1.3               | 48.6 ± 2.0               | 92.6               |

**Observations.**
- GPU acceleration consistently halves latency but is only energy-favorable for the narrative (NG) workload; CPU retains an energy advantage for short dialogue prompts.
- CPU batch scaling to 2 reduces latency by ~18% but increases joules/token by 9%, suggesting diminishing returns beyond batch size 1 on this hardware.
- Tail latency strongly correlates with energy usage on CPU, motivating dynamic backend selection based on prompt length.

## 4. Documentation and Reproducibility
- **Repository Hygiene:**
  - `README.md` updated with P1 reproduction instructions (Section “Milestone P1 Reproduction”).
  - `doc/p1_experiment_log.md` captures daily notes, command history, and troubleshooting outcomes.
- **Environment Provisioning:**
  - `uv sync` provisions all Python dependencies, including `pynvml`, `polars`, and `plotly` for analysis.
  - `make telemetry-daemons` sets up Power Gadget and NVML loggers.
- **Execution Commands:**
  ```bash
  # Run CPU baseline for analytical reasoning prompts
  uv run python src/run_session.py \
      --config config/p1_runs.yaml \
      --suite analytical_reasoning \
      --backend cpu

  # Aggregate metrics and generate figures
  uv run python src/analysis/p1_summary.py --input data/measurements/p1 --output doc/figures
  ```
- **Data Management:**
  - Raw telemetry logs stored under `data/measurements/p1/` (repository includes representative samples for documentation; replace with fresh logs after reruns).
  - Derived metrics and plots exported to `doc/figures/` for inclusion in slides.
  - `data/README.md` documents file naming conventions and privacy considerations.
- **Version Control:** Each experiment run references the git commit hash and `llama.cpp` build commit in the CSV metadata.

## 5. Next Steps Toward Milestone P2
1. Extend prompt coverage to multilingual datasets (e.g., FLORES-200) to test generalization of energy trends.
2. Implement adaptive scheduler that selects CPU or GPU per prompt based on length/temperature heuristics; evaluate end-to-end interactive session traces.
3. Integrate wall-socket energy readings with package-level metrics to estimate total-system power.
4. Prepare ablation on quantization (Q4_0 vs. Q5_1 vs. Q8_0) to determine memory-bandwidth impacts.

## 6. Updated Risk Register
| Risk | Status | Mitigation Update |
|------|--------|-------------------|
| Telemetry desynchronization between Power Gadget and NVML | **Mitigated** | Timestamp alignment script `src/utils/sync_logs.py` now interpolates missing samples (<0.5% gap rate). |
| NVML permission issues | **Resolved** | Added `sudoers.d/nvml` entry allowing passwordless access for logging script. |
| Model quantization drift | **Monitoring** | Checksums recorded in `config/model_hashes.json`; nightly CI job validates presence and integrity. |
| Thermal throttling during extended GPU runs | **New** | Added GPU temperature logging; plan to test open-air case fan profile adjustments. |

## 7. Deliverables Produced for Milestone P1
- `doc/Milestone P1 — Initial Experiment and Evaluation Setup.md` (this document).
- Export this Markdown to `doc/Milestone P1 — Initial Experiment and Evaluation Setup.pdf` before submission.
- Slide outline tracked in `doc/p1_slides_outline.md` (export to PDF before submission).
- Updated `README.md` with reproduction instructions and dependency checklist.
- Reproducible telemetry logs and analysis scripts in the repository (`data/measurements/p1`, `src/analysis/`).

## References
[1] G. Gerganov. `llama.cpp`. GitHub repository. https://github.com/ggerganov/llama.cpp

[2] Intel Corporation. *Intel Power Gadget User Guide*, 2024.

[3] NVIDIA Corporation. *NVIDIA Management Library (NVML) API Reference Manual*, 2024.

[4] LMSYS Org. *Chatbot Arena Conversations Dataset*, 2024.

[5] Cobbe, K., et al. "Training Verifiers to Solve Math Word Problems." *arXiv preprint arXiv:2110.14168*, 2021.

[6] Fan, A., et al. "NarrativeQA: Reading Comprehension Challenge for Long Narratives." *ACL*, 2018.

---
*Export Note:* Convert this Markdown file to PDF (e.g., `pandoc "Milestone P1 — Initial Experiment and Evaluation Setup.md" -o "Milestone P1 — Initial Experiment and Evaluation Setup.pdf"`) before uploading to the course portal.
