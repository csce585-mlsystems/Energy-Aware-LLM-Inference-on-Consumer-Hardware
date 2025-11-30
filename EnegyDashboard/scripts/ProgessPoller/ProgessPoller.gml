/// @function start_progress_polling()
/// @description Start polling the server for real-time progress updates

function start_progress_polling() {
    global.polling_active = true;
    global.server_progress = 0.0;
    global.server_step_name = "Initializing...";
    
    // Poll every 200ms
    if (!instance_exists(obj_progress_poller)) {
        instance_create_depth(0, 0, 0, obj_progress_poller);
    }
}

/// @function stop_progress_polling()
/// @description Stop polling when inference completes

function stop_progress_polling() {
    global.polling_active = false;
    
    if (instance_exists(obj_progress_poller)) {
        instance_destroy(obj_progress_poller);
    }
}

/// @function poll_server_status()
/// @description Send a GET request to /status to get current progress

function poll_server_status() {
    if (!global.polling_active) return;
    
    var _url = "http://127.0.0.1:5000/status";
    global.status_request_id = http_get(_url);
}

/// @function handle_status_response()
/// @description Process the /status response (call in Async HTTP event)
function handle_status_response() {
    var _id = async_load[? "id"];
    
    if (_id == global.status_request_id) {
        var _result_json = async_load[? "result"];
        
        try {
            var _data = json_parse(_result_json);
            global.server_progress = _data.progress;
            global.server_step_name = _data.step_name;
        } catch (_e) {
            // Silently fail - polling is non-critical
        }
    }
}
