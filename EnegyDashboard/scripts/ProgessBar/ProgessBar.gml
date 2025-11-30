/// @function draw_inference_progress()
/// @description Shows a progress bar and status while waiting for inference

function draw_inference_progress() {
    // Use REAL server progress
    var _progress = 0.0;
    var _step_text = "Ready";
    
    if (variable_global_exists("server_progress")) {
        _progress = global.server_progress;
        _step_text = global.server_step_name;
    }
    
    // If not running, ensure it says Ready
    if (global.http_request_id == -1) {
        _progress = 0.0;
        _step_text = "Ready - Press Space to Run";
    }
    
    // Layout - CENTERED
    var _screen_width = display_get_gui_width();
    var _screen_height = display_get_gui_height();
    
    var _bar_width = 600;
    var _bar_height = 30;
    var _bar_x = (_screen_width - _bar_width) / 2; // Center X
    var _bar_y = _screen_height - 100;             // Bottom area
    
    // Background
    draw_set_color(c_dkgray);
    draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_width, _bar_y + _bar_height, false);
    
    // Progress Fill (green)
    if (_progress > 0) {
        draw_set_color(c_lime);
        draw_rectangle(_bar_x, _bar_y, _bar_x + (_bar_width * _progress), _bar_y + _bar_height, false);
    }
    
    // Border
    draw_set_color(c_white);
    draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_width, _bar_y + _bar_height, true);
    
    // Status Text (Above Bar)
    draw_set_halign(fa_center); // Center text
    draw_set_color(c_white);
    draw_text(_bar_x + _bar_width/2, _bar_y - 25, _step_text);
    
    // Percentage Text (Inside Bar)
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    
    // Draw percentage with shadow for visibility
    var _pct_text = string(floor(_progress * 100)) + "%";
    var _text_x = _bar_x + _bar_width/2;
    var _text_y = _bar_y + _bar_height/2;
    
    draw_set_color(c_black);
    draw_text(_text_x + 1, _text_y + 1, _pct_text); // Shadow
    draw_set_color(c_white);
    draw_text(_text_x, _text_y, _pct_text);         // Text
    
    // Reset alignment
    draw_set_valign(fa_top);
    draw_set_halign(fa_left);
}

/// @function reset_inference_timer()
/// @description Call this when a new request starts
function reset_inference_timer() {
    inference_start_time = undefined;
}
