# Energy-Aware LLM Inference on Consumer Hardware
**Suprawee Pongpeeradech** | CSCE 585 | December 2025

---

## Slide 1: The Problem & Motivation

### Why This Matters
**AI is expensive.** Running models like ChatGPT usually needs:
- 🏢 Massive data centers
- ⚡ Tons of electricity
- 💰 Lots of money

**But your gaming PC is powerful!**
Can we run AI **locally** to save energy and keep data private?

### My Research Questions
1. **CPU vs GPU**: Which is actually better for energy?
2. **Settings**: Do threads or "offloading" layers help?
3. **The Trade-off**: Does going faster always save power?

**🗣️ SCRIPT**:
> "Hi everyone. We all know AI is expensive and power-hungry. Usually, you need a massive data center to run it. But modern gaming PCs are actually really powerful. So I wanted to know: Can we run these models at home efficiently? I asked three simple questions: Is CPU or GPU better? Which settings actually matter? And most importantly—does running it faster always mean saving energy, or is there a catch?"

---

## Slide 2: The Method

### My Setup
- **Computer**: Standard Gaming PC (Intel i5 + RTX 3060 12GB)
- **Model**: TinyLlama-1.1B (Small, efficient AI)
- **Tools**: Custom trackers for Power (Watts) and Speed (ms)

### What I Measured
1. **Speed** (Latency): How fast does it answer?
2. **Energy** (Joules): How much battery would it drain?
3. **Efficiency** (EDP): The balance between Speed and Energy.

### The Experiments (27 Runs)
I tested different combinations:
- **CPU Threads**: 1 vs 4 vs 8
- **GPU Layers**: 0 (None) vs 11 (Half) vs 22 (All)
- **Batch Size**: 128 vs 512 vs 1024

**🗣️ SCRIPT**:
> "Here's how I tested it. I used a standard gaming PC with an RTX 3060—nothing fancy. I tracked three things: Speed, Energy, and a combined 'Efficiency Score'. I ran 27 different experiments, tweaking things like how many CPU threads we use, or how much work we give to the GPU, to see what actually moves the needle."

---

## Slide 3: Experiments & Results

### The Big Picture: Energy vs. Speed

![Energy vs Latency Plot](https://github.com/user-attachments/assets/17dc8261-7bc1-45df-a114-f481c111c41c)

- 🟢 **Green (GPU)**: Fast & Efficient
- 🟠 **Orange (CPU)**: Slow & Power Hungry

### Key Numbers
- **CPU Best**: ~7,000 ms (Slow)
- **GPU Best**: ~6,000 ms (**Fastest**)
- **Efficiency Winner**: **GPU with 11 Layers** (Not 22!)

**🗣️ SCRIPT**:
> "Here are the results. This graph shows every test run. Green is GPU, Orange is CPU. You can see the GPU is generally much faster and uses less energy. But here's the shocker: The *fastest* setting (full GPU) wasn't the most *efficient*. Moving just HALF the layers to the GPU actually gave the best balance of speed and power savings."

---

## Slide 4: Discussion & Insights

### 4 Big Lessons
1.  ✅ **Half-GPU is the Efficiency King**: Offloading 11 layers beat offloading everything. It hits the sweet spot.
2.  ❌ **Faster ≠ Always Better**: Full GPU is faster, but burns power like crazy.
3.  🛑 **CPU Hits a Wall**: Adding more than 4 threads didn't help (memory limits).
4.  📉 **Batch Size Doesn't Matter**: For single users, it makes almost no difference.

### Limitations
- I only tested short prompts (chatbots).
- Long-running heat issues weren't tested.

**🗣️ SCRIPT**:
> "So, what did we learn? First, 'Half-GPU' is the efficiency king. It beats both CPU-only and Full-GPU. Second, we proved that going faster doesn't always save energy—sometimes it just burns power faster. Third, we found that CPU performance hits a wall after 4 threads. And finally, for a single user, changing batch size is basically a waste of time."

---

## Slide 5: Demo

### 🎮 Live Energy Dashboard

*(Play Video)*

**What you're seeing:**
1.  **Pipeline Running**: Automatically testing all 27 configs.
2.  **Real-time Power**: Watch the GPU power spike (40W → 180W) as it thinks.
3.  **Live Results**: The dashboard calculates the "Efficiency Score" instantly.

**Conclusion**:
We **can** run AI efficiently on consumer hardware—you just need the right settings!

**🗣️ SCRIPT**:
> "To prove this works, I built a live dashboard. In this video, you can see the system running the tests. Watch the green line—that's the GPU power spiking as it generates text. The dashboard calculates our efficiency score in real-time. This proves that with the right settings, your gaming PC is more than capable of running modern AI efficiently. Thank you!"
