# Energy-Aware LLM Inference on Consumer Hardware

## Group Info
- Suprawee Pongpeeradech  
  - Email: suprawee@email.sc.edu  

## Project Summary/Abstract
This project studies the trade-offs between CPU and GPU performance for large language model (LLM) inference on consumer hardware. Using **llama.cpp**, we evaluate an **Intel i5-13th Gen CPU** and an **NVIDIA RTX 3060 GPU** running TinyLlama-1.1B. We measure **energy consumption, latency, and throughput** across different prompt lengths and batch sizes. The goal is to find the “sweet spot” where energy efficiency and latency balance best, providing insights into when CPU or GPU is the most suitab...

## Problem Description
- **Problem description:** LLM inference is expensive in terms of energy and latency. On consumer hardware, it is unclear whether CPU or GPU provides the better trade-off for different workloads. This project investigates energy per token, p95 latency, and the energy-delay product to understand hardware efficiency.

- **Motivation**
  - Not all labs or students have access to enterprise GPUs; consumer hardware is more realistic.  
  - Energy efficiency is increasingly important for sustainable AI deployment.  
  - Understanding trade-offs helps guide hardware purchasing and workload scheduling.  

- **Challenges**
  - Ensuring fair comparisons between CPU and GPU backends (same prompts, configs, model).
  - Accurately measuring energy with NVML (GPU) and Intel Power Gadget (CPU) on Windows systems.
  - Managing workload design (prompt lengths, batch sizes) to capture meaningful results.  

## Contribution
### [`Extension of existing work`]
We extend related benchmarking work (e.g., llama.cpp, NVIDIA NVML, Intel Power Gadget studies) by focusing specifically on **consumer hardware** trade-offs in energy and latency for LLM inference.

- Contribution 1: Systematic comparison of CPU vs GPU inference under different workload types (short vs long prompts, single vs batched requests).  
- Contribution 2: Analysis of Energy-Delay Product (EDP) to identify the operating sweet spot balancing efficiency and latency.  
- Contribution 3: Practical insights and recommendations for small labs, students, and edge AI practitioners on when CPU or GPU makes the most sense.  

## References
- llama.cpp: https://github.com/ggerganov/llama.cpp  
- NVIDIA NVML: https://developer.nvidia.com/nvidia-management-library-nvml  
- Intel Power Gadget: https://www.intel.com/content/www/us/en/developer/articles/technical/intel-power-gadget.html

---

# Final Project Submission  

## Prerequisites

These instructions target **Windows 11** so you can complete the entire workflow without switching operating systems.

- Python **3.11** (install from [python.org](https://www.python.org/downloads/)).
- [Git for Windows](https://gitforwindows.org/) for cloning repositories.
- [Visual Studio Build Tools 2022](https://visualstudio.microsoft.com/downloads/) with the "Desktop development with C++" workload, which provides `cmake` and a modern MSVC compiler.
- NVIDIA GPU drivers with CUDA support for `llama.cpp` GPU execution and NVML telemetry access.
- `llama.cpp` built with both CPU and CUDA backends (steps below).
- [Intel Power Gadget](https://www.intel.com/content/www/us/en/developer/articles/tool/power-gadget.html) for CPU energy telemetry. *(Intel Power Gadget supports most Intel CPUs; AMD CPUs do not expose equivalent energy counters on Windows, so energy-per-token metrics would be unavailable on those systems.)*
- Python libraries for analysis: `matplotlib`, `pandas`, `numpy`, and `rich` (installed via `requirements.txt`).

> All commands below assume **Windows PowerShell**. Run PowerShell as Administrator when installing Intel Power Gadget or CUDA tooling.

## Directory Structure
```
|- data (mandatory)
|   |- power_logs.csv
|   |- latency_results.csv
|   |- prompts/
|   |   |- manual_prompts.json
|   \- prompt_templates/
|       |- analysis.txt
|       \- story.txt
|- src (mandatory)
|   |- run_cpu.py
|   |- run_gpu.py
|   |- telemetry.py
|   |- prompt_generator.py
|   \- workload.py
|- run.py (mandatory)
|- result.py (mandatory)
|- config/
|   \- prompt_config.json
```

## Step-by-Step Setup and Usage

### 1. Clone the repositories

```powershell
git clone https://github.com/ggerganov/llama.cpp.git
git clone https://github.com/<your-org>/MachineLearning.git
cd MachineLearning
```

### 2. Build `llama.cpp`

```powershell
cd ..\llama.cpp
cmake -S . -B build -DLLAMA_CUBLAS=ON
cmake --build build --config Release
```

This produces CPU and CUDA-enabled binaries in `llama.cpp/build/bin`. If you only need CPU inference, omit `-DLLAMA_CUBLAS=ON`.

### 3. Create and activate a Python environment

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install --upgrade pip
pip install -r requirements.txt
```

### 4. Configure telemetry tools

- Install Intel Power Gadget and ensure the background service is running (required for CSV export).
- Confirm the NVIDIA driver is installed; NVML ships with the driver and is accessed through the `pynvml` Python package.
- If Intel Power Gadget is unsupported on your CPU, CPU energy measurements will be skipped, but latency and throughput metrics will still be collected.

### 5. Prepare prompts

- **Manual mode:** Edit `data/prompts/manual_prompts.json` and add your own prompt strings or objects. Each entry will be replayed as-is for CPU and GPU runs.
- **Automatic mode:** Adjust `config/prompt_config.json` and the templates in `data/prompt_templates/` to control how prompts are synthesized. Templates use standard Python `{placeholder}` formatting and can define variable lists that will be combined into unique prompts.

### 6. Run experiments

```powershell
# Manual prompts (default)
python src/run_cpu.py --model C:\path\to\model.gguf
python src/run_gpu.py --model C:\path\to\model.gguf

# Automatically generated prompts
python src/run_cpu.py --model C:\path\to\model.gguf --prompt-source auto
python src/run_gpu.py --model C:\path\to\model.gguf --prompt-source auto
```

Use `--prompt-file` to point at a different manual JSON file, or `--prompt-config` to load an alternate automatic generation profile. The scripts accept additional flags for batch size, output length, and a `--dry-run` mode that skips llama.cpp execution while still logging prompt metadata.

Both runners send prompts to the llama.cpp CLI and log telemetry (including prompt IDs and character lengths) to `data/power_logs.csv` and `data/latency_results.csv`.

### 7. Analyze results

```powershell
python result.py
```

This generates plots and tables summarizing energy-per-token, throughput, and p95 latency for CPU vs. GPU workloads.

## Demo
- Video demonstration will show:  
  1. Running inference on CPU and GPU with llama.cpp.  
  2. Telemetry collection with NVML and Intel Power Gadget.
  3. Visualization of energy per token and p95 latency.  
  4. Final table and graph showing CPU vs GPU trade-offs.  

