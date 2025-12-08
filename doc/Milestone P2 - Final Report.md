# Milestone P2 - Final Report: Energy-Aware LLM Inference on Consumer Hardware

**Author:** Suprawee Pongpeeradech    
**Date:** December 2 2025  

## 1.Motivation and Problem Definition

Large Language Models (LLMs) are used everywhere across every industry nowadays (for example in healthcare, finance, and education).Their deployment of LLM is relying on high-end devices that include CPUs and GPUs like NVIDIA A100s which are mainly data-center GPUs used for large-scale inference. These systems consume a lot of enegy which costs a lot of money, and has limited accessibility for researchers, small companies, and hobbyists, and also increases carbon emissions. However, the demad for high-end laptops and gaming PCs are increasing significantly because these devices now come with powerful consumer GPUs capable of running optimized models. Running LLMs locally can help make access more open, lower carbon emissions, improve privacy, reduce latency, and make less use of computer resources. Key to make this move possible are designs that work well and efficiency methods like editing, filtering, compression, and cutting.This project studies the `trade-offs` between running `TinyLlama-1.1B` on a normal user setup. Especially, we look at how hardware backends (CPU vs.GPU), compression, and system factors (threads, batch size) affect speed (latency) and efficiency (energy use).

**Research Questions:**
1. Regarding delay and energy use for consumer-grade LLM inference , how do hardware backends (the CPU vs. the GPU) compare?
2. How do the number of CPU threads, GPU layer sharing, and batch size affects performance?
3. Does making the most of the GPU always mean that using less energy, or are there trade-offs?

### 1.1 Related Work
LLM quantization methods (like GPTQ and AWQ) have mostly been explored in the context of data-center hardware, where memory and compute resources are much larger. However, research on “race-to-sleep” strategies [3] shows that sometimes running a system faster even at higher power can actually save energy overall. By applying this idea to consumer-grade device, which have much stricter power and temperature limit than servers, this project aim to address a gap in the existing work and see how these technique behave outside high-end data-center environments.## 2. Methodology

### 2.1 System Setup
*   **Hardware:** Consumer PC with `Intel Core i5-13400F` and `NVIDIA RTX 3060 GPU`.*   **Software:** `llama.cpp`, Python 3.11, `pynvml` (GPU telemetry), Intel Power Gadget (CPU telemetry), GameMaker.
*   **Model:** `TinyLlama - 1.1B - Chat-v1.0.Q4_0.gguf`.

### 2.2 Metrics
I measure on three main things:
 1. `Latency (ms):` This is the whole time it take for the model to respond, from the start to the end.
 2. `Energy (Joules):` How much power the CPU and GPU use while the inference is running.
 3. `Energy-Delay Product (EDP):` A measure that takes into account both speed and energy use (J x s).  Lower numbers mean that the system works better overall.

### 2.3 Experimental Design
I ran the experiments in two main phases:

1. Baseline Comparison: I used three types of prompts 1. short dialogue, 2. analytical reasoning, and 3. narrative generation to compare CPU and GPU inferece.

2. Ablation Studies:

    - Thread Scaling: I checked how speed changes when 1, 4, and 8 CPU threads are used.

    - Offloading Layers: I change how many layers were sent to the GPU (0, 11, and 22).
    - Batch Size: To see how the scale changes speed, I try out different prompt batch sizes (128, 512, and 1024).**Table 1: Experimental Configurations**

| Config ID | Backend | Threads | GPU Layers | Batch Size | Description |
|-----------|---------|---------|------------|------------|-------------|
| `cpu-t1/4/8` | CPU | 1, 4, 8 | 0 | 128 | Thread scaling baseline |
| `gpu-l0` | GPU | 4 | 0 | 128 | CPU-only via GPU backend (control) |
| `gpu-l11` | GPU | 4 | 11 | 128 | 50% layers offloaded (hybrid) |
| `gpu-l22` | GPU | 4 | 22 | 128 | 100% layers offloaded (full) |
| `gpu-b*` | GPU | 4 | 22 | 128-1024 | Batch size scaling |

I tried three questions from the Short Dialogue suite for the each setting. The longest one was 146 characters.  Using system timers, I measured the times it took from when the prompt was sent to when the answer were sent.  I used hardware monitoring tools (the pynvml for the GPU [4] and Intel Power Gadget for the CPU [5]) to record data at 10 Hz in order to keep the track of how much energy being used.  So that the findings would be the same every time, all the test were done on the same machine with temperature controls.

## 3. Results and Analysis

### 3.1 Baseline Performance: CPU vs. GPU

Across 27 experimental runs covering all the different configurations, I observed the following average performance:

| Backend | Avg Latency (ms) | Avg Energy (J) | Avg EDP (J·s) | Configuration |
|---------|------------------|----------------|---------------|---------------|
| **CPU** | 6,943 | 150 | 1,045 | Thread scaling (1, 4, 8) |
| **GPU** | 6,020 | 186 | 1,121 | Layer/batch variations |

As a side note, the Energy-Delay Product (EDP = Energy x Latency) is a measure of how efficient something is. Lower number mean better total performance.For this short-context job, the CPU background worked better than expected, which was not what was expected.Key Finding: The GPU (full offloading) is still fastest in terms of pure lag (~6s vs ~6.4s for best CPU), but it uses a lot more power (~188J vs ~130J).  So, the multi-threaded CPU setup (`cpu-t8}) turns out to be the best choice overall.

<img width="966" height="577" alt="image" src="https://github.com/user-attachments/assets/ea79d10a-8b43-422e-b236-f96bb2cfdb3a" />

_Figure 1: Energy vs. Latency scatter plot. The CPU runs (top-left/center) show a favorable balance of reasonable latency and lower energy consumption compared to the higher-power GPU runs._

Interpretation: In this case, the figure shows that GPU acceleration has the lowest real delay, but it uses a lot of energy to get there.  When the CPU has 8 threads, it's in a "sweet spot" where lag is about the same as the GPU (about 400ms slower) and energy use is about 30% lower.

<img width="1268" height="492" alt="image" src="https://github.com/user-attachments/assets/aea91a84-b07e-47fb-b07c-49b6005f98e7" />

_Figure 2: Average latency and energy for both the CPU and GPU setups._

### 3.2 Ablation Studies

The ablation tests give a clearer picture of which settings actually help performance:

#### A. CPU Thread Scaling

Speed goes up a lot when you go from 1 thread to 4.  It's interesting that increasing the numbers of threads to 8 made thing even better in this running, which had the lowest delay (about 6411 ms) and the best energy efficiency of the whole experiment.

<img width="741" height="472" alt="image" src="https://github.com/user-attachments/assets/602a676f-88f3-4ffe-b4eb-53e9dd9b62ed" />

_Figure 3: CPU thread scaling results. Latency drops significantly when moving from 1 to 4 threads. Moving to 8 threads provides an additional speedup and, crucially, achieves the best energy efficiency (lowest EDP) in this set of experiments, reducing latency to ~6,411 ms._

Interpretation: The results show that the CPU can handle up to 8 threads of work with this task.  In earlier tests, memory speed seemed to slow things down after 4 threads. This "cleaner" test, on the other hand, shows that using more cores help the CPU finishes the job faster and go into a low-power state earlier, making it more efficient.

#### B. GPU Layer Offloading
Offloading layers to the GPU turned out to be the single most effective optimization in our experiments. My results clearly show that moving more layers onto the GPU gives a big boost in performance.

- `0 layers (CPU only):` This is the slowest setup, around 15,000 ms or more.

- `11 layers (partial offload):` About 50 percent faster than CPU only.

- `22 layers (full GPU offload):` This is the fastest setup, around 6,000 - 8,000 ms.

<img width="749" height="470" alt="image" src="https://github.com/user-attachments/assets/01e9f159-47e3-47b7-bf55-be999971fcc8" />

_Figure 4: A study of GPU layer sharing ablation.  Taking on more layer lowers delay linearly, but the GPU uses a lot of power, so the EDP is higher than in the optimized CPU-only run.  The "partial offload" (11 layers) approach, which works well in other situations, didn't work as well here because it took more works to keep both the CPU and the powerful GPU to be busy._

Interpretation: The GPU has better raw speed, as shown by the straight drop in delay.  But the economy measure (EDP) is lower because the GPU uses more power (about 188J overall) than it saves.  This shows a very important trade-off: offloading speeds up the model, but for short jobs on this consumer-grade hardware, it draws more power.

#### C. Batch Size Scaling

I tried batch sizes of 128, 512, and 1024 using full GPU offloading. The results show that increasing batch size is not really help for single-prompt inference. Latency only improves a little, since the workload is mostly limited by memory, not by how much compute does the GPU have.

<img width="727" height="466" alt="image" src="https://github.com/user-attachments/assets/4d9c5115-1cca-4ff1-a21a-099d75aca33b" />

_Figure 5: Batch size growth for GPU inference with full layer dumping is shown in Figure 5. For tasks with only one question, batch size doesn't really matter, as shown by the almost flat line that goes through batch sizes 128, 512, and 1024._

### 3.3 Power Characteristics
The real-time power readings let us see how the amount of power usage changes during GPU inference. When building something, the GPU used about 160 - 180 W of power. When there are no prompts, it definitely drop back to low or idle levels.

<img width="920" height="472" alt="image" src="https://github.com/user-attachments/assets/4ffe1247-2540-496b-a994-b24d1fe5636e" />

_Figure 6: Real-time power usage of the NVIDIA RTX 3060 during a typical inference run. Power jumps to around 160–180 W during token generation and drops to about 20–40 W during prompt handling and idle time. The total energy used is the area is under this curve._

### 3.4 Energy-Delay Product (EDP) Analysis

To compare configurations more fair, we calculated the `Energy-Delay Product (EDP = Energy x Latency)` for each run. A lower EDP mean a setup is more efficient overall, since it balances both how fast is it and how much energy it uses.

**Key Findings:**

| Rank | Configuration | Avg EDP (J·s) | Interpretation |
|------|---------------|---------------|----------------|
| **1st** | `cpu-t8` (8 threads) | **834** | **Best overall efficiency** - High speed and low power |
| 2nd | `cpu-t4` (4 threads) | 1,048 | Strong CPU performance |
| 3rd | `gpu-b1024` (Batch 1024) | 1,077 | Best GPU result, slightly behind CPU |
| ... | ... | ... | ... |
| 8th | `gpu-l11` (11 layers) | 1,186 | Previous winner, now less efficient due to overhead |

**Surprising Result**: The **CPU (8 threads)** had the lowest EDP (834 J·s), beat all GPU setups.This goes against the general belief that GPUs are always better at reasoning.  For this small model (1.1B) and short quick job, the GPU's high power usage and the work it takes to move data to it are greater than its raw computing edge.1.CPU can win small tasks: The CPU has an advantage for short runs of inference because it can quickly ramp up and down without using a lot of idle power.
2. GPU Overhead: The 1.1B model is so small that the GPU's huge parallelism isn't fully used, but it still uses more power (about 180W vs. 130W).

**Limitations**:

- I only tried suggestions for Short Dialogue that were about 146 characters long. The results may be different for longer entries or other jobs like math or code.

- I didn't look into temperature slowdown, but it might be important for longer runs on consumer GPUs with less powerful cooling.

### 4.3 Unexpected Findings

GPU batch size insensitivity: We expected bigger batch sizes to boost the throughputs a little bit, but only seen about 10 - 15% changes in latency. This suggest that on consumer GPUs with limited the memory bandwidth, single-prompt workloads don’t really gain much from batching like they do on data center GPUs with HBM.

Partial offloading penalty: The 11-layer (about half offloaded) setups sometimes did worse than we expected, likely because CPU-GPU transfer costs eat up the benefits of parallelism. For this model size, it seems like offloading works best as an almost all-or-nothing choice.

## 5. Conclusion

This project demonstrates that energy-aware reasoning can be done on common hardware and can be made better in real life.  Some of the most important things I learned from 27 different ablation tests are:

**Primary insights:**

1. The 8-thread CPU setup has the lowest Energy-Delay Product (~834 J·s), which was a kind of surprising.
2. The GPU is the fastest, but it uses a lot of power. The Full GPU that sharing is still the fastest (about 6.1s vs. 6.4s), but it uses about 45% more power per run.
3. Thread scaling works: going from 4 to 8 threads made the system more efficient, which suggests that the memory problem wasn't as bad in this run.
4. The size of the model is important. For a 1.1B model, the "heavy lifting" power of a separate GPU might not be worth to the extra cost in power.**Practical recommendations:**

- For the fastest speed, using a GPU that can handle all the work.
- To be saving power and battery life, use the CPU with 8 threads. It worked just as well but uses only 70% of the energy.

**Future work:**

- To lower the amount of memory bandwidth needed, try bit-width compression with a lower bit-width, like 2-bit or 1-bit.

- Look into schedules with both CPU and GPU to better distribute the work.

- Test the data on computers and other battery-powered devices to see if they still hold true in mobile settings.

- Think about dynamic layer dumping, which changes based on how much memory is on the GPU.

## 6. Deliverables

This project includes:

1. Experimental data: The latency and the energy measurements from all runs:
`data/latency_results.csv, data/power_logs.csv`

2.Analysis figures: Seven plots are showing the main ablation results:
`doc/figures/*.png`

3. Interactive dashboard: A GameMaker-based tool for live power monitoring during inference (See in `./EnergyDashboard`)

4. Reproducible pipeline: An automated experiment runner (run_pipeline.ps1) plus analysis scripts

## Demo
- **Interactive Dashboard:**
  I have built a custom GameMaker dashboard to visualize power and latency data collected from inference runs.
  Video Demo: [Demonstration Video](https://youtu.be/LRHLlwpiLdg)

  *To run the dashboard locally:*
  1. Start the Python server: `uv run python src/demo_server.py`
  2. Open `EnergyDashboard/EnergyDashboard.yyp` in GameMaker and click Run.

## References

[1] **TinyLlama**: An Open-Source Small Language Model,. Zhang et al., 2024. https://github.com/jzhang38/TinyLlama

[2] **llama.cpp**: Inference of Meta's LLaMA model in pure C/C++,. Gerganov, G., 2023. https://github.com/ggerganov/llama.cpp

[3] **Race-to-Sleep Energy Management**: Lebeck, A. R., et al. "Power Aware Page Allocation." ASPLOS 2000. https://www3.cs.stonybrook.edu/~anshul/courses/cse591_s16/power_page.pdf

[4] **NVIDIA Management Library (NVML)**: NVIDIA Corporation. https://developer.nvidia.com/nvidia-management-library-nvml

[5] **Intel Power Gadget**: Intel Corporation. https://www.intel.com/content/www/us/en/developer/articles/tool/power-gadget.html

