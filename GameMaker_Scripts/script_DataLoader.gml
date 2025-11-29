/// @function load_energy_data()
/// @description Loads the gamemaker_export.json file and stores it in global.energy_data

function load_energy_data() {
    var _filename = "gamemaker_export.json";
    
    if (file_exists(_filename)) {
        var _buffer = buffer_load(_filename);
        var _json_string = buffer_read(_buffer, buffer_string);
        buffer_delete(_buffer);
        
        try {
            global.energy_data = json_parse(_json_string);
            global.current_run_index = 0;
            show_debug_message("✅ Data loaded successfully: " + string(array_length(global.energy_data.runs)) + " runs.");
        } catch (_e) {
            show_debug_message("❌ Error parsing JSON: " + _e.message);
            global.energy_data = undefined;
        }
    } else {
        show_debug_message("⚠️ File not found: " + _filename);
        global.energy_data = undefined;
    }
}

/// @function get_run_by_id(_run_id)
function get_run_by_id(_run_id) {
    if (is_undefined(global.energy_data)) return undefined;
    
    var _runs = global.energy_data.runs;
    for (var i = 0; i < array_length(_runs); i++) {
        if (_runs[i].run_id == _run_id) {
            return _runs[i];
        }
    }
    return undefined;
}
