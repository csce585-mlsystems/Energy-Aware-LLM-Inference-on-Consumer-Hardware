global.energy_data = undefined;
global.current_run_index = 0;
global.http_request_id = -1;
global.server_progress = 0.0;
global.server_step_name = "Ready";
global.last_poll_time = 0;

// 🔹 Load initial data from JSON file
load_energy_data();
