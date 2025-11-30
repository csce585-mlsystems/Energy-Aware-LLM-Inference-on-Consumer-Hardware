sprite_index = button_1;

// RUN/PLOT GPU HERE
global.server_progress = 0.0;
global.server_step_name = "Starting...";
reset_inference_timer();
request_random_inference();
