/// @function load_energy_data()
/// @description Loads the initial dataset from the included JSON file.
function load_energy_data() {
    var _filename = "gamemaker_export.json";
    
    if (file_exists(_filename)) {
        var _buffer = buffer_load(_filename);
        var _json_string = buffer_read(_buffer, buffer_string);
        buffer_delete(_buffer);
        
        try {
            var _data = json_parse(_json_string);
            global.energy_data = _data; // <--- CRITICAL FIX: Store the data globally!
            global.current_run_index = 0;
            
            // Populate History from the loaded file
            if (variable_struct_exists(_data, "runs")) {
                var _runs = _data.runs;
                for (var i = 0; i < array_length(_runs); i++) {
                    var _r = _runs[i];
                    if (_r.backend == "cpu") global.history_cpu = _r;
                    if (_r.backend == "gpu") global.history_gpu = _r;
                    array_push(global.all_runs, _r); // Add to history list
                }
                
                // Set current run to one of them so the graph isn't empty
                if (variable_global_exists("history_gpu")) global.current_run = global.history_gpu;
                else if (variable_global_exists("history_cpu")) global.current_run = global.history_cpu;
                
                show_debug_message("✅ Data loaded. History populated.");
            }
        } catch (_e) {
            show_debug_message("❌ Error parsing JSON: " + _e.message);
        }
    } else {
        show_debug_message("⚠️ File not found: " + _filename);
    }
}

/// @function request_inference(_prompt, _backend)
/// @description Requests the latest available trace for the given backend.
/// @param _prompt Unused in this mode, but kept for signature compatibility
/// @param _backend "cpu" or "gpu" (string)

function request_inference(_prompt, _backend) {
    var _url = "http://127.0.0.1:5000/latest_trace?backend=" + _backend;
    
    show_debug_message("🚀 Fetching latest trace from " + _url);
    
    // Store the request ID in a global variable
    global.server_progress = 0.1;
    global.server_step_name = "Requesting...";
    global.user_has_run_inference = true; // <--- Flag user interaction
    global.http_request_id = http_get(_url);
}

/// @function handle_http_response()
/// @description Call this in the HTTP Async Event of your object.
/// @function load_history_data()
/// @description Requests the full history of runs from the server.
function load_history_data() {
    var _url = "http://127.0.0.1:5000/history";
    show_debug_message("📜 Fetching history from " + _url);
    
    // Trigger progress bar animation
    global.server_progress = 0.5;
    global.server_step_name = "Loading History...";
    
    global.http_request_history_id = http_get(_url);
}

/// @function handle_http_response()
/// @description Call this in the HTTP Async Event of your object.
function handle_http_response() {
    var _id = async_load[? "id"];
    
    // 1. Handle History Data (GET /history)
    if (_id == global.http_request_history_id) {
        var _status = async_load[? "status"];
        if (_status == 0) {
            var _result_json = async_load[? "result"];
            try {
                var _data = json_parse(_result_json);
                if (variable_struct_exists(_data, "runs")) {
                    var _runs = _data.runs;
                    
                    // Clear existing runs to avoid duplicates if reloading
                    global.all_runs = [];
                    
                    for (var i = 0; i < array_length(_runs); i++) {
                        array_push(global.all_runs, _runs[i]);
                    }
                    
                    global.history_loaded = true;
                    global.history_loaded = true;
                    global.server_progress = 1.0;
                    global.server_step_name = "Done!";
                    output("Loaded " + string(array_length(_runs)) + " historical runs.");
                }
            } catch (_e) {
                show_debug_message("❌ Error parsing history: " + _e.message);
            }
        }
    }
    
    // 2. Handle Latest Trace (GET /latest_trace)
    if (_id == global.http_request_id) {
        var _status = async_load[? "status"];
        if (_status == 0) {
            var _result_json = async_load[? "result"];
            try {
                var _data = json_parse(_result_json);
                
                if (variable_struct_exists(_data, "error")) {
                    show_debug_message("⚠️ Server Error: " + _data.message);
                    output("Error: " + _data.message);
                    return;
                }
                
                // Store the response so the graph can see it
                global.energy_data = _data;
                global.current_run_index = 0;
                
                // Store the full result
                var _run = _data.runs[0];
                global.current_run = _run;
                
                // Save to History for quick CPU vs GPU comparison on Live Trace view
                if (_run.backend == "cpu") global.history_cpu = _run;
                if (_run.backend == "gpu") global.history_gpu = _run;
                
                // NOTE: Do NOT add to global.all_runs here!
                // That array is populated from /history endpoint and should only contain real runs.
                // Clicking "Run CPU/GPU" just visualizes the latest file, it doesn't create a new run.
                
                global.http_request_id = -1; // Done
                global.server_progress = 1.0;
                global.server_step_name = "Done!";
                
                output("Loaded " + string_upper(_run.backend) + " trace!");
                
            } catch (_e) {
                show_debug_message("❌ Error parsing JSON: " + _e.message);
                output("Failed to parse server response.");
            }
        } else if (_status < 0) {
             output("Server not reachable. Is it running?");
        }
    }
}
