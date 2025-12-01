# Energy-Aware LLM Inference on Consumer Hardware
## Benchmarking TinyLlama-1.1B on CPU vs GPU

## Group Info
- Suprawee Pongpeeradech
  - Email: <suprawee@email.sc.edu>

## Project Summary/Abstract
### This project investigates the energy-latency trade-offs of running Large Language Models (LLMs) on consumer-grade hardware. We benchmark TinyLlama-1.1B across CPU and GPU backends, analyzing the impact of thread scaling, layer offloading, and batch size. Our findings reveal that partial GPU offloading often yields the best energy efficiency (EDP), challenging the assumption that "faster is always better."

## Problem Description
- Problem description: Deploying LLMs on consumer devices is challenging due to limited compute and strict power constraints. We aim to find the optimal configuration that balances inference speed (latency) with energy consumption (Joules).
- Motivation
  - **Accessibility:** Enabling researchers and hobbyists to run LLMs locally without expensive data-center GPUs.
  - **Energy Efficiency:** Reducing the carbon footprint and electricity cost of large-scale inference.
  - **Privacy:** Processing sensitive data locally instead of sending it to the cloud.
- Challenges
  - **Memory Bandwidth:** Consumer DDR4 RAM bottlenecks CPU inference speed.
  - **Thermal Throttling:** Sustained high-power GPU usage can lead to performance degradation.
  - **Measurement Accuracy:** synchronizing high-frequency power telemetry with software events is difficult.

## Contribution
- [`Extension of existing work`]

### [`Extension of existing work`]
I extend the "Race-to-Sleep" energy management strategy [3] to the domain of LLM inference. I improve upon standard benchmarking by:
- Integrating real-time power telemetry (Intel Power Gadget & NVML) directly into the inference loop.
- Analyzing the Energy-Delay Product (EDP) to find the "sweet spot" between speed and power.

## References
### References
@misc{zhang2024tinyllama,
  title={TinyLlama: An Open-Source Small Language Model},
  author={Zhang, Peiyuan and Zeng, Guangtao and Wang, Tianduo and Wei, Lu},
  year={2024},
  publisher={GitHub},
  journal={GitHub repository},
  howpublished={\url{https://github.com/jzhang38/TinyLlama}}
}

@misc{gerganov2023llamacpp,
  title={llama.cpp: Inference of Meta's LLaMA model in pure C/C++},
  author={Gerganov, Georgi},
  year={2023},
  publisher={GitHub},
  journal={GitHub repository},
  howpublished={\url{https://github.com/ggerganov/llama.cpp}}
}

@inproceedings{lebeck2000power,
  title={Power Aware Page Allocation},
  author={Lebeck, Alvin R and Fan, Xiaobo and Zeng, Heng and Ellis, Carla},
  booktitle={ASPLOS},
  year={2000}
}

---

# < The following is only applicable for the final project submission >

## Dependencies
### This project requires the following:
- Python 3.11+
- Windows 10/11 (Native or WSL2)
- Intel Power Gadget (for CPU telemetry)
- NVIDIA Drivers (for GPU telemetry)

For Python users: Please use [uv](https://docs.astral.sh/uv/) as your package manager instead of `pip`. Your repo must include both the `uv.lock` and `pyproject.toml` files.

## Directory Structure
```
|- config
|   |- p1_runs.yaml        # Baseline experiment config
|   |- p2_ablation.yaml    # Ablation study config
|- data (mandatory)
|   |- latency_results.csv # Main telemetry log
|   |- power_logs.csv      # Power summary log
|- doc
|   |- figures/            # Generated plots
|   |- Milestone P2...md   # Final Report
|- src (mandatory)
|   |- analysis/           # Analysis scripts
|   |- run_session.py      # Experiment runner
|   |- telemetry.py        # Power/Latency logging
|- EnegyDashboard          # GameMaker Interactive Dashboard
|- run_pipeline.ps1 (mandatory) # Main execution script
|- pyproject.toml
|- uv.lock
```

## How to Run
- **Step 1: Install Dependencies**
  ```bash
  uv sync
  ```

- **Step 2: Download Model**
  ```bash
  uv run download_model.py
  ```

- **Step 3: Run Experiments**
  To execute the full pipeline (Baseline + Ablation Studies), run the main PowerShell script:
  ```powershell
  ./run_pipeline.ps1
  ```
  *Alternatively, run specific phases:*
  ```bash
  uv run python src/run_session.py --config config/p2_ablation.yaml
  ```

- **Step 4: Analyze Results**
  To generate the plots and summary report:
  ```bash
  uv run python src/analysis/generate_report.py
  ```

## Demo
- **Interactive Dashboard:**
  I have built a custom GameMaker dashboard to visualize power and latency data collected from inference runs.
  Video Demo: (haven't uploaded yet)***----

  *To run the dashboard locally:*
  1. Start the Python server: `uv run python src/demo_server.py`
  2. Open `EnergyDashboard/EnergyDashboard.yyp` in GameMaker and click Run.
