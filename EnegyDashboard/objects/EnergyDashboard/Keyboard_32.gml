global.server_progress = 0.0;
global.server_step_name = "Starting...";
reset_inference_timer();
request_inference("Explain quantum physics", "gpu");
