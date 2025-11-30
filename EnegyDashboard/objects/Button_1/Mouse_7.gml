sprite_index = button_1;

// FETCH LATEST GPU DATA
global.server_progress = 0.0;
global.server_step_name = "Fetching...";

request_latest_data("gpu");

output("Loading GPU Data...")