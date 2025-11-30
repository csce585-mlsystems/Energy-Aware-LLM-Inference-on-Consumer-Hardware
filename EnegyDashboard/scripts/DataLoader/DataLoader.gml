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
/// @description Sends an HTTP POST request to the Python server to trigger inference.
/// @param _prompt The text prompt to send (string)
/// @param _backend "cpu" or "gpu" (string)

function request_inference(_prompt, _backend) {
    var _url = "http://127.0.0.1:5000/generate";
    
    var _payload = {
        prompt: _prompt,
        backend: _backend
    };
    
    var _json_payload = json_stringify(_payload);
    
    var _headers = ds_map_create();
    ds_map_add(_headers, "Content-Type", "application/json");
    
    show_debug_message("🚀 Sending request to " + _url);
    
    // Store the request ID in a global variable if you need to track it
    global.http_request_id = http_request(_url, "POST", _headers, _json_payload);
    
    ds_map_destroy(_headers);
}

/// @function handle_http_response()
/// @description Call this in the HTTP Async Event of your object.
function handle_http_response() {
    var _id = async_load[? "id"];
    
    // 1. Handle the Final Result (POST /generate)
    if (_id == global.http_request_id) {
        var _status = async_load[? "status"];
        if (_status == 0) {
            var _result_json = async_load[? "result"];
            try {
                var _data = json_parse(_result_json);
                
                // 🔹 Store the response so the graph can see it
                global.energy_data = _data;
                global.current_run_index = 0;
                
                // Store the full result
                var _run = _data.runs[0];
                global.current_run = _run;
                
                // Save to History for Comparison
                if (_run.backend == "cpu") global.history_cpu = _run;
                if (_run.backend == "gpu") global.history_gpu = _run;
                
                global.http_request_id = -1; // Done
            } catch (_e) {
                show_debug_message("❌ Error parsing JSON: " + _e.message);
            }
        }
    }
    
    // 2. Handle Status Polling (GET /status)
    var _url = async_load[? "url"];
    if (!is_undefined(_url) && string_pos("/status", _url) > 0) {
        var _status = async_load[? "status"];
        if (_status == 0) {
            var _result_json = async_load[? "result"];
            try {
                var _data = json_parse(_result_json);
                
                // Update Progress Bar
                if (variable_struct_exists(_data, "progress")) {
                    global.server_progress = _data.progress;
                    global.server_step_name = _data.step_name;
                }
                
                // Update Real-time Graph (ONLY if still processing)
                if (variable_struct_exists(_data, "partial_trace") && global.http_request_id != -1) {
                    var _partial = _data.partial_trace;
                    if (array_length(_partial) > 0) {
                        // Create a temporary "run" object to display
                        var _temp_run = {
                            run_id: "Running...",
                            backend: "Processing...",
                            latency_ms: 0,
                            energy_joules: 0,
                            power_trace: _partial
                        };
                        
                        // Update the "current" display run
                        global.current_run = _temp_run;
                    }
                }
            } catch (_e) {}
        }
    }
}
