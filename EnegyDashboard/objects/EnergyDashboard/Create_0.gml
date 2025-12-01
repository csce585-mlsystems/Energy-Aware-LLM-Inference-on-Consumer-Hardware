global.energy_data = undefined;
global.current_run_index = 0;
global.http_request_id = -1;
global.server_progress = 0.0;
global.server_step_name = "Ready";
global.last_poll_time = 0;
progress_reset_timer = 0;
global.user_has_run_inference = false; // Only show analysis after user interaction
global.ablation_mode = 0; // 0=Layers, 1=Threads, 2=Batch

// 🔹 Load initial data from JSON file
load_energy_data();
load_history_data();
