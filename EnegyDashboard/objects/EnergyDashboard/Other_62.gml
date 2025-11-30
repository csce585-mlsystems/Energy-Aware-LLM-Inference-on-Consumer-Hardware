// Handle the main inference response
handle_http_response();

// ALSO poll for status updates while waiting
if (global.http_request_id != -1) {
    // Poll status endpoint
    if (!variable_global_exists("last_poll_time")) {
        global.last_poll_time = current_time;
    }
    
    // Poll every 300ms
    if (current_time - global.last_poll_time > 300) {
        http_get("http://127.0.0.1:5000/status");
        global.last_poll_time = current_time;
    }
}

// Parse status responses
var _result = async_load[? "result"];
if (_result != undefined) {
    // Check if this is a status response (contains "progress")
    if (string_pos("progress", _result) > 0 && string_pos("runs", _result) == 0) {
        try {
            var _status_data = json_parse(_result);
            global.server_progress = _status_data.progress;
            global.server_step_name = _status_data.step_name;
        } catch (_e) {
            // Ignore parse errors
        }
    }
}