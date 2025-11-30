sprite_index = button;

// RUN/PLOT CPU HERE
global.server_progress = 0.0;
global.server_step_name = "Starting...";
reset_inference_timer();

// Pick a random scientific prompt
var _prompts = [
    "Summarize the latency and energy trade-offs between CPU and GPU inference for TinyLlama on consumer hardware.",
    "List three configuration tweaks that improve GPU inference efficiency when using llama.cpp.",
    "Explain the concept of 'Race to Sleep' in the context of mobile processors.",
    "Write a Python script to measure power consumption using NVML.",
    "Compare the memory bandwidth requirements of 4-bit vs 8-bit quantization."
];
var _random_prompt = _prompts[irandom(array_length(_prompts) - 1)];

// ALWAYS run CPU
request_inference(_random_prompt, "cpu");
// If you want to force CPU, use: request_inference("Your prompt here", "cpu");

output("Running CPU")