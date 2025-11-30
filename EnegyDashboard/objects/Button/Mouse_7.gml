sprite_index = button;

// FETCH LATEST CPU DATA
global.server_progress = 0.0;
global.server_step_name = "Fetching...";

request_latest_data("cpu");

output("Loading CPU Data...")