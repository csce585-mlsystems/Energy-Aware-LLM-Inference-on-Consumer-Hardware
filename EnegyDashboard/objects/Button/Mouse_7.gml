sprite_index = button;

// RUN/PLOT CPU HERE
global.server_progress = 0.0;
global.server_step_name = "Starting...";
reset_inference_timer();
request_random_inference(); // Uses the smart prompt selector
// If you want to force CPU, use: request_inference("Your prompt here", "cpu");