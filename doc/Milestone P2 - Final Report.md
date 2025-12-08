# Milestone P2 - Final Report: Energy-Aware LLM Inference on Consumer Hardware

**Author:** Suprawee Pongpeeradech    
**Date:** December 2 2025  

## 1. Motivation and Problem Definition

Large Language Models (LLMs) are used everywhere across every industry nowadays (for example in healthcare, finance, and education). Their deployment of LLM is relying on high-end devices that include CPUs and GPUs like NVIDIA A100s which are mainly data-center GPUs used for large-scale inference. These systems consume a lot of enegy which costs a lot of money, and has limited accessibility for researchers, small companies, and hobbyists, and also increases carbon emissions. However, the demad for high-end laptops and gaming PCs are increasing significantly because these devices now come with powerful consumer GPUs capable of running optimized models. Running LLMs locally can help make access more open, lower carbon emissions, improve privacy, reduce latency, and make less use of computer resources. Key to make this move possible are designs that work well and efficiency methods like editing, filtering, compression, and cutting.

This project studies the `trade-offs` between running `TinyLlama-1.1B` on a normal user setup. Especially, we look at how hardware backends (CPU vs. GPU), compression, and system factors (threads, batch size) affect speed (latency) and efficiency (energy use).

**Research Questions:**
1. Regarding delay and energy use for consumer-grade LLM inference, how do hardware backends (CPU vs. GPU) compare?
2. How do the number of CPU threads, GPU layer sharing, and batch size affect performance?
3. Does making the most of the GPU always mean using less energy, or are there trade-offs?

### 1.1 Related Work
LLM quantization methods (like GPTQ and AWQ) have mostly been explored in the context of data-center hardware, where memory and compute resources are much larger. However, research on “race-to-sleep” strategies [3] shows that sometimes running a system faster even at higher power can actually save energy overall. By applying this idea to consumer-grade devices, which have much stricter power and temperature limits than servers, this project aims to address a gap in the existing work and see how these techniques behave outside high-end data-center environments.

## 2. Methodology

### 2.1 System Setup
*   **Hardware:** Consumer PC with `Intel Core i5-13400F` and `NVIDIA RTX 3060 GPU`.
*   **Software:** `llama.cpp`, Python 3.11, `pynvml` (GPU telemetry), Intel Power Gadget (CPU telemetry), GameMaker.
*   **Model:** `TinyLlama-1.1B-Chat-v1.0.Q4_0.gguf`.

### 2.2 Metrics
I measure three key metrics:
1. `Latency (ms):` This is the total time it takes for the model to produce a response from start to finish.
2. `Energy (Joules):` The amount of energy the CPU/GPU package uses while running the inference.
3. `Energy-Delay Product (EDP):` A combined metric (J x s) that captures both energy use and speed. Lower values mean better overall efficiency.

### 2.3 Experimental Design
I ran the experiments in two main phases:

1. Baseline Comparison: I compared CPU and GPU inference using three different prompt types: Short Dialogue, Analytical Reasoning, and Narrative Generation.

2. Ablation Studies:

    - Thread Scaling: I tested how performance changes when using 1, 4, and 8 CPU threads.

    - Layer Offloading: I varied how many layers were offloaded to the GPU (0, 11, and 22).

    - Batch Size: I experimented with different prompt batch sizes (128, 512, and 1024) to see how scaling affects performance.

**Table 1: Experimental Configurations**

| Config ID | Backend | Threads | GPU Layers | Batch Size | Description |
|-----------|---------|---------|------------|------------|-------------|
| `cpu-t1/4/8` | CPU | 1, 4, 8 | 0 | 128 | Thread scaling baseline |
| `gpu-l0` | GPU | 4 | 0 | 128 | CPU-only via GPU backend (control) |
| `gpu-l11` | GPU | 4 | 11 | 128 | 50% layers offloaded (hybrid) |
| `gpu-l22` | GPU | 4 | 22 | 128 | 100% layers offloaded (full) |
| `gpu-b*` | GPU | 4 | 22 | 128-1024 | Batch size scaling |

For each configuration, I tested 3 prompts from the Short Dialogue suite (average length: 146 characters). I measured end-to-end latency from when the prompt was submitted to when the response finished using system timers. To track energy use, I collected data from hardware telemetry tools (pynvml for the GPU [4] and Intel Power Gadget for the CPU [5]), sampling at 10 Hz. All experiments were run on the same machine under controlled thermal conditions so the results would be consistent and reproducible.

## 3. Results and Analysis

### 3.1 Baseline Performance: CPU vs. GPU

Across 27 experimental runs covering all the different configurations, I observed the following average performance:

| Backend | Avg Latency (ms) | Avg Energy (J) | Avg EDP (J·s) | Configuration |
|---------|------------------|----------------|---------------|---------------|
| **CPU** | 7,152 | 191 | 1,367 | Thread scaling (1, 4, 8) |
| **GPU** | 12,594 | 159 | 2,001 | Layer/batch variations |

Note on EDP: The Energy-Delay Product (EDP = Energy x Latency) is an efficiency metric where lower values mean better overall performance because it takes both speed and energy use into account. Even though the GPU showed higher average latency in some of the partial offloading tests, its lower energy consumption helped keep its EDP fairly competitive.

Key Finding: The GPU’s average latency looks higher at first, but that’s mostly because the results include the partial offloading setups (0 and 11 layers). When the model is run with full GPU offloading (22 layers), the latency drops significantly well below the CPU baseline. This trend is clear in the ablation results shown below.

<img width="1191" height="745" alt="image" src="https://github.com/user-attachments/assets/c17216cc-0c2d-4778-9a61-1eed480f8c6f" />

_Figure 1: Energy vs. Latency scatter plot for all 27 runs. The three clear clusters represent: fully-offloaded GPU (bottom-left, fastest and most efficient), CPU-only (top-right, slowest and least efficient), and partially-offloaded GPU (middle area, with in-between performance). This shows how much the choice of configuration can shift where you land in the overall energy–latency trade-off space._

Interpretation: The plot shows three clear performance groups. Full GPU offloading (22 layers) lands in the low latency range of about 6 to 8 seconds and uses around 160 J, putting it on the Pareto frontier. CPU-only and partial GPU setups use two to three times more energy, which means they are not very efficient. The spread in GPU results also shows how important it is to choose the right number of layers to offload.

<img width="1681" height="647" alt="image" src="https://github.com/user-attachments/assets/c67ce962-548c-43a3-82de-e1f2c04553e8" />

_Figure 2: Average latency and energy for both the CPU and GPU setups._

### 3.2 Ablation Studies

The ablation tests give a clearer picture of which settings actually help performance:

#### A. CPU Thread Scaling

Going from 1 to 4 to 8 CPU threads improves speed, but the gains level off pretty quickly. The 8-thread setup gives the fastest CPU time at about 7152 ms on average, but memory bandwidth limits keep it from scaling any further.

<img width="1017" height="622" alt="image" src="https://github.com/user-attachments/assets/cc8936fe-6759-4bfa-ac0f-69385eb697b2" />

_Figure 3: CPU thread scaling results. Latency drops sharply when going from 1 to 4 threads (about 40 percent faster), but there is less than 10 percent improvement from 4 to 8 threads, suggesting the system is limited by memory bandwidth, not compute._

Interpretation: The smaller gains past 4 threads suggest that TinyLlama inference on this consumer machine is limited more by memory than by compute. Even if we add more CPU threads, they still have to wait on DDR4 memory (about 25 GB/s) to read the model weights from DRAM during autoregressive decoding, so performance does not scale much further.

#### B. GPU Layer Offloading
Offloading layers to the GPU turned out to be the single most effective optimization in our experiments. My results clearly show that moving more layers onto the GPU gives a big boost in performance.

- `0 layers (CPU only):` This is the slowest setup, around 15,000 ms or more.

- `11 layers (partial offload):` About 50 percent faster than CPU only.

- `22 layers (full GPU offload):` This is the fastest setup, around 6,000 - 8,000 ms.

<img width="971" height="631" alt="image" src="https://github.com/user-attachments/assets/cc7f063b-ea51-4b15-828e-e3a4570e5a4e" />

_Figure 4: GPU layer offloading ablation study. Latency drops almost linearly as more transformer layers are offloaded to the GPU. Going from 0 to 22 layers cuts latency by about 2 to 3 times and also reduces energy use, making this the most impactful optimization in our experiments._

Interpretation: The almost linear drop in latency as more layers are offloaded shows that the GPU’s tensor cores, backed by fast GDDR6 memory (about 360 GB/s), handle transformer computations much more efficiently than the CPU’s SIMD units. This backs up the common practice in LLM deployment of using the GPU as much as possible whenever it is available.

#### C. Batch Size Scaling

I tried batch sizes of 128, 512, and 1024 using full GPU offloading. The results show that increasing batch size does not really help for single-prompt inference. Latency only improves a little, since the workload is mostly limited by memory, not by how much compute the GPU has.

<img width="1055" height="688" alt="image" src="https://github.com/user-attachments/assets/ab755714-31c3-4394-9908-eca91275ccdf" />

_Figure 5: Batch size scaling for GPU inference with full layer offloading. The almost flat line across batch sizes 128, 512, and 1024 shows that for single-prompt workloads, batch size does not really affect performance._

### 3.3 Power Characteristics
From the real-time power measurements, we can see how power usage changes over the course of GPU inference. During active generation, the GPU draws about 160–180 W, and then clearly drops back down to low, idle levels between prompts.

<img width="1718" height="712" alt="image" src="https://github.com/user-attachments/assets/35c354d5-d0c2-4dab-b4d6-d1020301659b" />

_Figure 6: Real-time power usage of the NVIDIA RTX 3060 during a typical inference run. Power jumps to around 160–180 W during token generation and drops to about 20–40 W during prompt handling and idle time. The total energy used is the area under this curve._

### 3.4 Energy-Delay Product (EDP) Analysis

To compare configurations more fairly, we calculated the `Energy-Delay Product (EDP = Energy x Latency)` for each run. A lower EDP means a setup is more efficient overall, since it balances both how fast it is and how much energy it uses.

**Key Findings:**

| Rank | Configuration | Avg EDP (J·s) | Interpretation |
|------|---------------|---------------|----------------|
| **1st** | `gpu-l11` (11 layers) | **972** | **Best overall efficiency** - balances moderate GPU offloading with low latency |
| 2nd | `gpu-l0` (0 layers) | 1,146 | CPU-only but with GPU power measurement overhead |
| 3rd | `cpu-t4` (4 threads) | 1,250 | Best CPU-only configuration |
| 4th | `cpu-t1` (1 thread) | 1,406 | Single-threaded baseline |
| 5th | `cpu-t8` (8 threads) | 1,420 | Diminishing returns from more threads |

**Surprising Result**: The partial GPU offloading configuration (`gpu-l11` with 11 layers) achieved the **lowest EDP**, outperforming even full GPU offloading (`gpu-l22`). This suggests that:

Surprising result: The partial GPU offload setup (gpu-l11, 11 layers) actually got the lowest EDP, even better than full GPU offload (gpu-l22). This means:

1. Partial offloading can give the best trade-off: full offloading is faster, but it also draws more power, while 11 layers seems to hit a sweet spot.

2. Faster is not always more efficient: gpu-l22 has lower latency, but its EDP is higher (about 2160 J·s) because the GPU stays at high power for longer.

**Limitations**:

- We only tested Short Dialogue prompts (around 146 characters), so results might change for longer inputs or other tasks like code or math.

- We did not study thermal throttling, which could matter for longer runs on consumer GPUs with weaker cooling.

### 4.3 Unexpected Findings

GPU batch size insensitivity: We expected bigger batch sizes to boost throughput, but only saw about 10-15% change in latency. This suggests that on consumer GPUs with limited memory bandwidth, single-prompt workloads don’t really gain much from batching like they do on data center GPUs with HBM.

Partial offloading penalty: The 11-layer (about half offloaded) setups sometimes did worse than we expected, likely because CPU-GPU transfer costs eat up the benefits of parallelism. For this model size, it seems like offloading works best as an almost all-or-nothing choice.

## 5. Conclusion

This project shows that energy-aware inference on consumer hardware is doable and can be optimized in practice. Across 27 ablation experiments with different settings, I was able to pull out a few main takeaways:

**Primary insights:**

1. Partial GPU offloading can give the best EDP: The 11-layer setup had the lowest Energy-Delay Product (about 972 J x s), beating both CPU-only and full GPU offload. This shows there is a sweet spot between speed and energy use.

2. Full GPU offloading is fastest: Offloading 22 layers gives the lowest latency (around 6-8 seconds), but it uses more energy, leading to a higher EDP (about 2160 J x s).

3. The best setup depends on your goal: You have to choose based on whether you care more about latency, energy, or a balance of both (EDP).

4. CPU scaling hits limits: After 4 threads, CPU speed stops improving much and EDP gets worse because memory bandwidth becomes the bottleneck.

5. Batch size does not matter much: For single-prompt inference, changing batch size from 128 to 1024 only changes latency by about 10-15 percent.

**Practical recommendations:**

- For latency-critical applications: Use full GPU offloading (22 layers) with the default batch size (128). This gives the fastest responses.

- For energy-constrained devices: The GPU is still a good choice. Even though it has higher peak power, it finishes 40–50 percent faster and ends up using less total energy.

For CPU-only deployments: Use 4–8 threads. Beyond that, the speedup is small and not really worth it.

**Future work:**

- Try lower bit-width quantization (like 2-bit or 1-bit) to cut down memory bandwidth needs.

- Explore hybrid CPU+GPU scheduling to better balance the workload.

- Run tests on battery-powered devices (like laptops) to see if the energy results still hold in mobile settings.

- Look into dynamic layer offloading that adapts based on how much GPU memory is available.

## 6. Deliverables

This project includes:

1. Experimental data: Latency and energy measurements from all runs:
`data/latency_results.csv, data/power_logs.csv`

2. Analysis figures: Seven plots showing the main ablation results:
`doc/figures/*.png`

3. Interactive dashboard: A GameMaker-based tool for live power monitoring during inference (See in `./EnergyDashboard`)

4. Reproducible pipeline: An automated experiment runner (run_pipeline.ps1) plus analysis scripts

All code, data, and documentation are included in the project repository.
## References

[1] **TinyLlama**: An Open-Source Small Language Model. Zhang et al., 2024. https://github.com/jzhang38/TinyLlama

[2] **llama.cpp**: Inference of Meta's LLaMA model in pure C/C++. Gerganov, G., 2023. https://github.com/ggerganov/llama.cpp

[3] **Race-to-Sleep Energy Management**: Lebeck, A. R., et al. "Power Aware Page Allocation." ASPLOS 2000. https://www3.cs.stonybrook.edu/~anshul/courses/cse591_s16/power_page.pdf

[4] **NVIDIA Management Library (NVML)**: NVIDIA Corporation. https://developer.nvidia.com/nvidia-management-library-nvml

[5] **Intel Power Gadget**: Intel Corporation. https://www.intel.com/content/www/us/en/developer/articles/tool/power-gadget.html

