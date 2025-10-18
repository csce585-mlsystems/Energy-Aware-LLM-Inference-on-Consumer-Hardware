# Milestone P0 — Project Proposal and Motivation

## Project Overview
- **Course:** CSCE 585 — Machine Learning Systems (Fall 2025)
- **Project Title:** Energy-Aware TinyLlama Inference on Consumer Hardware
- **Team Configuration:** Suprawee Pongpeeradech (solo project)
- **Contact:** suprawee@email.sc.edu

## 1. Introduction
Large Language Models (LLMs) enable natural-language applications ranging from personal assistants to tutoring platforms. The TinyLlama-1.1B model offers an accessible entry point for experimentation, yet end users often deploy it on commodity desktops that combine mid-range Central Processing Units (CPUs) and Graphics Processing Units (GPUs). Existing benchmarks typically target data-center accelerators, leaving practitioners without guidance on balancing energy consumption and latency on affordable hardware. This project investigates how to orchestrate TinyLlama inference across CPU-only and GPU-accelerated pipelines while respecting interactive latency targets.

**Problem Statement.** When executing TinyLlama-1.1B on consumer-grade hardware, under which workload characteristics (prompt length, batch size, response truncation) does a CPU-only pipeline achieve better energy efficiency than a GPU-accelerated pipeline without violating interactive latency constraints?

Answering this question requires a reproducible measurement harness, carefully curated workloads, and joint consideration of throughput, power draw, and user-perceived responsiveness.

## 2. Motivation and Context
### Practical Relevance
- Students and small laboratories frequently rely on desktops or shared workstations, where GPU access is limited or intermittent.
- Energy consumption directly affects operating costs, thermal budgets, and noise constraints in shared environments.
- Current guidance is fragmented across forums and repository issues; a consolidated evaluation helps practitioners make informed scheduling choices.

### Systems Perspective
- Scheduling inference between CPU and GPU backends is a core ML systems problem involving hardware-resource management, workload partitioning, and telemetry instrumentation.
- Understanding how power and latency respond to batching, quantization, and runtime configuration enables system designers to optimize end-to-end user experience.

### Background and Related Work
The llama.cpp project publishes throughput-oriented benchmarks across heterogeneous devices but rarely reports energy metrics, particularly for CPU-only configurations on the same host [1]. Tasdemir et al. evaluate energy-aware intrusion detection on NVIDIA BlueField Data Processing Units (DPUs), highlighting the benefits of telemetry integration on specialized hardware not readily available to students [2]. Kapoor et al. explore SmartNIC-accelerated inference, emphasizing latency reductions but omitting holistic energy analyses [3]. These studies motivate a focused examination of CPU versus GPU TinyLlama inference on commodity devices where both backends are viable.

## 3. Objectives and Research Questions
1. **Quantify Energy-Latency Trade-offs.** Measure joules per generated token, average latency, and tail latency across CPU and GPU pipelines for representative prompt suites.
2. **Characterize Workload Regimes.** Identify prompt lengths and batch sizes where CPU execution is preferable, as well as regimes that favor GPU acceleration.
3. **Provide Reproducible Guidance.** Release scripts, configuration files, and documentation that enable classmates to replicate early results using `uv`-managed Python environments.

## 4. Methodology
### 4.1 Hardware and Software Configuration
- **CPU:** Intel Core i5-13600K (14 cores, 5.1 GHz boost)
- **GPU:** NVIDIA GeForce RTX 3060 (12 GB VRAM)
- **Memory:** 32 GB DDR5
- **Operating System:** Windows 11 Pro (23H2) with Windows Subsystem for Linux 2 for telemetry aggregation
- **Inference Runtime:** `llama.cpp` compiled with CPU and CUDA backends (commit hash recorded per experiment)
- **Environment Management:** `uv` with `pyproject.toml` and `uv.lock` to guarantee dependency reproducibility

### 4.2 Workload Design
- **Prompt Suites:**
  1. Short-form dialogue prompts (≤128 tokens input)
  2. Analytical reasoning prompts (256–512 tokens input)
  3. Narrative generation prompts (≥768 tokens input)
- **Batch Sizes:** 1, 2, and 4 concurrent prompts via llama.cpp batching support.
- **Response Length:** Fixed upper bound of 256 output tokens to normalize decoding workload.
- **Randomness Control:** Seeded prompt sampling and deterministic decoding (temperature 0.1, top-p 0.9) for comparability.

### 4.3 Instrumentation and Data Collection
- Intel Power Gadget command-line interface for CPU package power and cumulative energy readings.
- NVIDIA Management Library (NVML) via `pynvml` to sample GPU power, clocks, utilization, and board energy.
- High-resolution monotonic clocks to capture wall-clock latency and tokens-per-second.
- Synchronized sampling at 200 ms intervals with warm-up passes discarded to mitigate cold-start transients.
- CSV-based logging with timestamps, workload identifiers, runtime flags, and telemetry statistics stored under `data/`.

### 4.4 Baselines and Experimental Conditions
- **Baseline:** CPU-only inference using 12 inference threads and batch size 1.
- **Comparisons:**
  - GPU-accelerated inference using CUDA backend with default streaming multiprocessor scheduling.
  - CPU inference with increased batch sizes (2, 4) to explore throughput-energy trade-offs.
  - Optional hybrid mode (GPU prompt processing followed by CPU decoding) if time permits.

### 4.5 Analysis Workflow
- Aggregate metrics per workload condition and compute mean ± standard deviation over three runs.
- Derive Energy-Delay Product (EDP) to capture combined efficiency and performance (defined when first used).
- Generate Pareto front visualizations, heatmaps, and bar charts using Python notebooks stored in `src/analysis/`.

## 5. Evaluation Plan
- **Metrics:** Joules per output token, average latency, 95th-percentile latency, tokens per second, and Energy-Delay Product (EDP).
- **Statistical Tests:** Paired t-tests comparing CPU versus GPU metrics within identical workload configurations; Holm–Bonferroni correction applied when evaluating multiple prompt suites.
- **Success Criteria:**
  1. Document at least two workload configurations where CPU execution reduces energy per token by ≥15% while keeping latency within 20% of GPU performance.
  2. Highlight at least one configuration where GPU execution dominates both energy and latency, informing scheduling decisions.
  3. Provide actionable configuration recommendations (e.g., batch size thresholds) grounded in measured data.

## 6. Feasibility, Resources, and Schedule
### Resource Availability
All required hardware, telemetry tools, and llama.cpp builds are available on the project workstation. Prior experiments confirm that telemetry APIs function correctly under administrative privileges.

### Work Plan (Weeks 1–8)
| Week | Activities | Deliverables |
|------|------------|--------------|
| 1 | Validate llama.cpp builds, collect smoke-test telemetry samples | Setup log in `doc/setup_notes.md` |
| 2 | Finalize prompt templates and configuration schema | `config/prompt_config.json` committed |
| 3 | Automate telemetry synchronization and CSV logging | Prototype scripts in `src/` with dry-run proof |
| 4 | Polish proposal and README reproducibility section | This document + README updates |
| 5 | Execute short-prompt CPU vs. GPU experiments | Preliminary plots stored in `src/analysis/` |
| 6 | Extend experiments to medium/long prompts, refine batching | Interim Milestone P1 notebook |
| 7 | Perform statistical analysis, generate comparative charts | Draft results notebook |
| 8 | Prepare Milestone P1 report and slides | Slide deck + README reproduction checklist |

## 7. Risks and Mitigations
| Risk | Potential Impact | Mitigation Strategy |
|------|------------------|---------------------|
| Telemetry sampling jitter or dropped readings | Noisy energy calculations | Implement warm-up period, interpolate missing samples, and cross-validate with Windows Performance Monitor |
| NVML permission or driver conflicts | Incomplete GPU power data | Pre-test NVML scripts with admin rights and document driver versions |
| Quantization mismatches between CPU and GPU builds | Non-comparable accuracy/performance | Standardize TinyLlama-1.1B GGUF Q4_0 artifacts and verify checksums |
| Data management overhead | Delays in analysis | Automate log aggregation and provide Makefile targets for reproducing plots |

## 8. Expected Contributions and Deliverables
- **Measurement Harness:** Reusable Python scripts for orchestrating llama.cpp runs, telemetry capture, and log aggregation.
- **Dataset Release:** Organized CSV logs with metadata enabling secondary analysis.
- **Guidance Document:** README section summarizing best-practice configurations for CPU and GPU TinyLlama inference.
- **Presentation Artifacts:** Slide decks and written reports aligned with course submission requirements.

## References
[1] G. Gerganov. `llama.cpp`. GitHub repository. https://github.com/ggerganov/llama.cpp

[2] K. Tasdemir, R. Khan, F. Siddiqui, S. Sezer, F. Kurugollu, and A. Bolat. "An Investigation of Machine Learning Algorithms for High-bandwidth SQL Injection Detection Utilising BlueField-3 DPU Technology." *IEEE SOCC*, 2023.

[3] R. Kapoor, D. C. Anastasiu, and S. Choi. "ML-NIC: Accelerating Machine Learning Inference using Smart Network Interface Cards." *Frontiers in Computer Science*, 2025.

---
*Next Step:* Export this Markdown file to PDF (e.g., via Pandoc or VS Code) and upload it as `Milestone P0 — Project Proposal and Motivation.pdf` inside the `doc/` directory per course instructions.
