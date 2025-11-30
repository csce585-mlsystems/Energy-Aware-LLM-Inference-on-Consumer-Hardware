/// @function request_random_inference()
/// @description Picks a random prompt and toggles backend, then requests inference.
function request_random_inference() {
    // 1. Define a list of REAL prompts from your project (data/prompts/manual_prompts.json)
    var _prompts = [
        "Summarize the latency and energy trade-offs between CPU and GPU inference for TinyLlama on consumer hardware.",
        "List three configuration tweaks that improve GPU inference efficiency when using llama.cpp.",
        "Explain the concept of 'Race to Sleep' in the context of mobile processors.",
        "Write a Python script to measure power consumption using NVML.",
        "Compare the memory bandwidth requirements of 4-bit vs 8-bit quantization."
    ];
    
    // 2. Pick a random prompt
    var _prompt_index = irandom(array_length(_prompts) - 1);
    var _selected_prompt = _prompts[_prompt_index];
    
    // 3. Toggle Backend (or randomize)
    // We'll use a global variable to toggle back and forth for comparison
    if (!variable_global_exists("current_backend")) {
        global.current_backend = "gpu";
    } else {
        if (global.current_backend == "gpu") global.current_backend = "cpu";
        else global.current_backend = "gpu";
    }
    
    // 4. Reset Timer & Request
    reset_inference_timer();
    request_inference(_selected_prompt, global.current_backend);
    
    show_debug_message("🎲 Random Request: " + _selected_prompt + " [" + string_upper(global.current_backend) + "]");
}