# Energy-Aware LLM Inference on Consumer Hardware

## Group Info
- Suprawee Pongpeeradech  
  - Email: suprawee@email.sc.edu  

## Project Summary/Abstract
This project studies the trade-offs between CPU and GPU performance for large language model (LLM) inference on consumer hardware. Using **llama.cpp**, we evaluate an **Intel i5-12th Gen CPU** and an **NVIDIA RTX 3060 GPU** running TinyLlama-1.1B. We measure **energy consumption, latency, and throughput** across different prompt lengths and batch sizes. The goal is to find the “sweet spot” where energy efficiency and latency balance best, providing insights into when CPU or GPU is the most suitab...

## Problem Description
- **Problem description:** LLM inference is expensive in terms of energy and latency. On consumer hardware, it is unclear whether CPU or GPU provides the better trade-off for different workloads. This project investigates energy per token, p95 latency, and the energy-delay product to understand hardware efficiency.

- **Motivation**
  - Not all labs or students have access to enterprise GPUs; consumer hardware is more realistic.  
  - Energy efficiency is increasingly important for sustainable AI deployment.  
  - Understanding trade-offs helps guide hardware purchasing and workload scheduling.  

- **Challenges**
  - Ensuring fair comparisons between CPU and GPU backends (same prompts, configs, model).  
  - Accurately measuring energy with NVML (GPU) and RAPL/Power Gadget (CPU).  
  - Managing workload design (prompt lengths, batch sizes) to capture meaningful results.  

## Contribution
### [`Extension of existing work`]
We extend related benchmarking work (e.g., llama.cpp, NVIDIA NVML, Intel RAPL studies) by focusing specifically on **consumer hardware** trade-offs in energy and latency for LLM inference.

- Contribution 1: Systematic comparison of CPU vs GPU inference under different workload types (short vs long prompts, single vs batched requests).  
- Contribution 2: Analysis of Energy-Delay Product (EDP) to identify the operating sweet spot balancing efficiency and latency.  
- Contribution 3: Practical insights and recommendations for small labs, students, and edge AI practitioners on when CPU or GPU makes the most sense.  

## References
- llama.cpp: https://github.com/ggerganov/llama.cpp  
- NVIDIA NVML: https://developer.nvidia.com/nvidia-management-library-nvml  
- Intel RAPL / Power Gadget: https://www.intel.com/content/www/us/en/developer/articles/technical/intel-power-gadget.html  

---

# Final Project Submission  

## Dependencies
- Python 3.11  
- Ubuntu 22.04  
- llama.cpp (compiled with CPU and CUDA backends)  
- NVIDIA NVML / pyNVML  
- Intel RAPL / Intel Power Gadget  
- Matplotlib / Pandas for result visualization  

## Directory Structure
```
|- data (mandatory)
|   |- power_logs.csv
|   |- latency_results.csv
|- src (mandatory)
|   |- run_cpu.py
|   |- run_gpu.py
|   |- telemetry.py
|- run.py (mandatory)
|- result.py (mandatory)
```

## How to Run
- Clone llama.cpp and build with both CPU and CUDA backends.  
- Install dependencies with uv:  
  ```bash
  uv pip install -r requirements.txt
  ```  

- Run CPU experiments:  
  ```bash
  python src/run_cpu.py
  ```  

- Run GPU experiments:  
  ```bash
  python src/run_gpu.py
  ```  

- Collect and plot results:  
  ```bash
  python result.py
  ```  

## Demo
- Video demonstration will show:  
  1. Running inference on CPU and GPU with llama.cpp.  
  2. Telemetry collection with NVML and RAPL.  
  3. Visualization of energy per token and p95 latency.  
  4. Final table and graph showing CPU vs GPU trade-offs.  

