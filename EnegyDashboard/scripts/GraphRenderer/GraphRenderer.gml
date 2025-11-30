/// @function draw_energy_graph(_x, _y, _width, _height)
/// @description Draws the power trace for the current run..

function draw_energy_graph(_x, _y, _width, _height) {
    if (is_undefined(global.energy_data)) {
        draw_text(_x, _y, "No Data Loaded");
        return;
    }
    
    var _runs = global.energy_data.runs;
    var _run = _runs[global.current_run_index];
    var _trace = _run.power_trace;
    var _count = array_length(_trace);
    
    if (_count == 0) return;
    
    // Define max power for scaling (used by grid and plot)
    var _max_watts = 250;
    
    // Layout - CENTERED
    var _screen_width = display_get_gui_width();
    var _screen_height = display_get_gui_height();
    
    // Define Graph Size
    _width = 800;
    _height = 400;
    _x = (_screen_width - _width) / 2;
    _y = (_screen_height - _height) / 2 - 50; // Shift up slightly to make room for progress bar
    
    // Draw Title
    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text_transformed(_screen_width/2, 30, "Energy-Aware Inference Dashboard", 2, 2, 0);
    
    // Background
    draw_set_color(make_color_rgb(20, 20, 25)); // Dark blue-gray
    draw_set_alpha(0.9);
    draw_rectangle(_x, _y, _x + _width, _y + _height, false);
    draw_set_alpha(1.0);
    
    // Border
    draw_set_color(c_dkgray);
    draw_rectangle(_x, _y, _x + _width, _y + _height, true);
    
    // Draw Axes and Grid
    draw_set_color(c_gray);
    
    // Y-axis grid lines (power levels)
    var _grid_steps = 5;
    for (var i = 0; i <= _grid_steps; i++) {
        var _grid_y = _y + (_height / _grid_steps) * i;
        draw_set_alpha(0.2);
        draw_line(_x, _grid_y, _x + _width, _grid_y);
        draw_set_alpha(1.0);
        
        // Y-axis labels (Watts)
        var _watt_value = _max_watts - (_max_watts / _grid_steps) * i;
        draw_set_color(c_ltgray);
        draw_set_halign(fa_right);
        draw_text(_x - 10, _grid_y - 8, string(floor(_watt_value)) + "W");
    }
    
    // X-axis grid lines (time)
    var _time_steps = 4;
    for (var i = 0; i <= _time_steps; i++) {
        var _grid_x = _x + (_width / _time_steps) * i;
        draw_set_color(c_gray);
        draw_set_alpha(0.2);
        draw_line(_grid_x, _y, _grid_x, _y + _height);
        draw_set_alpha(1.0);
        
        // X-axis labels (seconds)
        var _time_sec = (_run.latency_ms / 1000) * (i / _time_steps);
        draw_set_color(c_ltgray);
        draw_set_halign(fa_center);
        draw_text(_grid_x, _y + _height + 10, string_format(_time_sec, 1, 1) + "s");
    }
    
    // Axis titles
    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(_x + _width/2, _y + _height + 35, "Time (seconds)");
    
    draw_set_halign(fa_center);
    var _y_label_x = _x - 60;
    var _y_label_y = _y + _height/2;
    draw_text_transformed(_y_label_x, _y_label_y, "Power (Watts)", 1, 1, 90);

    
    // --- PLOT TRACES ---
    
    // Helper function to draw a single trace
    var _draw_trace = function(_run_data, _color, _alpha, _x, _y, _width, _height, _max_watts) {
        var _t = _run_data.power_trace;
        var _c = array_length(_t);
        if (_c == 0) return;
        
        draw_set_color(_color);
        draw_set_alpha(_alpha);
        draw_primitive_begin(pr_linestrip);
        for (var i = 0; i < _c; i++) {
            var _val = _t[i];
            var _px = _x + (i / (_c - 1)) * _width;
            var _py = _y + _height - (_val / _max_watts) * _height;
            if (_py < _y) _py = _y;
            draw_vertex(_px, _py);
        }
        draw_primitive_end();
        draw_set_alpha(1.0);
    };
    
    // 1. Draw CPU History (if exists) - Orange
    if (variable_global_exists("history_cpu") && !is_undefined(global.history_cpu)) {
        _draw_trace(global.history_cpu, c_orange, 0.6, _x, _y, _width, _height, _max_watts);
    }
    
    // 2. Draw GPU History (if exists) - Lime
    if (variable_global_exists("history_gpu") && !is_undefined(global.history_gpu)) {
        _draw_trace(global.history_gpu, c_lime, 0.6, _x, _y, _width, _height, _max_watts);
    }
    
    // 3. Draw Current Live Run (Bright White/Aqua)
    if (variable_global_exists("current_run") && !is_undefined(global.current_run)) {
        var _run = global.current_run;
        var _col = (_run.backend == "gpu") ? c_lime : c_orange;
        if (_run.backend == "Processing...") _col = c_aqua; // Live color
        
        _draw_trace(_run, _col, 1.0, _x, _y, _width, _height, _max_watts);
        
        // Update _run for the info panel to show the LATEST active one
        // (This ensures the text matches the live line)
    } else {
        // Fallback if no current run, show one of the histories in the panel
        if (variable_global_exists("history_gpu")) _run = global.history_gpu;
        else if (variable_global_exists("history_cpu")) _run = global.history_cpu;
    }

    // --- INTERACTIVE HOVER ---
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    
    if (_mx >= _x && _mx <= _x + _width && _my >= _y && _my <= _y + _height) {
        // Calculate which data point we're hovering over
        var _rel_x = _mx - _x;
        var _hover_ratio = _rel_x / _width;
        
        // Get the current run's trace to calculate index
        var _current_trace = [];
        if (!is_undefined(_run)) {
            _current_trace = _run.power_trace;
        }
        
        if (array_length(_current_trace) > 0) {
            var _hover_index = floor(_hover_ratio * (array_length(_current_trace) - 1));
            _hover_index = clamp(_hover_index, 0, array_length(_current_trace) - 1);
            
            var _hover_val = _current_trace[_hover_index];
            var _hover_time = (_run.latency_ms / 1000) * _hover_ratio;
            
            // Draw Vertical Line
            var _line_x = _x + _hover_ratio * _width;
            draw_set_color(c_white);
            draw_set_alpha(0.5);
            draw_line(_line_x, _y, _line_x, _y + _height);
            draw_set_alpha(1.0);
            
            // Draw Tooltip
            var _tip_w = 140;
            var _tip_h = 50;
            var _tip_x = _mx + 15;
            var _tip_y = _my - 25;
            
            // Keep tooltip on screen
            if (_tip_x + _tip_w > _screen_width) _tip_x = _mx - _tip_w - 15;
            
            draw_set_color(c_black);
            draw_set_alpha(0.9);
            draw_rectangle(_tip_x, _tip_y, _tip_x + _tip_w, _tip_y + _tip_h, false);
            draw_set_alpha(1.0);
            draw_set_color(c_white);
            draw_rectangle(_tip_x, _tip_y, _tip_x + _tip_w, _tip_y + _tip_h, true);
            
            draw_set_halign(fa_left);
            draw_set_color(c_ltgray);
            draw_text(_tip_x + 10, _tip_y + 8, "Time: " + string_format(_hover_time, 1, 2) + "s");
            
            var _power_color = (_run.backend == "gpu") ? c_lime : c_orange;
            draw_set_color(_power_color);
            draw_text(_tip_x + 10, _tip_y + 28, "Power: " + string(floor(_hover_val)) + " W");
        }
    }
    
    // --- SIDE PANEL INFO ---
    var _panel_x = _x + _width + 20;
    var _panel_y = _y;
    var _panel_w = 250;
    
    // Panel Background
    draw_set_color(make_color_rgb(30, 30, 35));
    draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_w, _panel_y + _height, false);
    draw_set_color(c_dkgray);
    draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_w, _panel_y + _height, true);
    
    // Legend
    draw_set_halign(fa_left);
    draw_set_color(c_white);
    draw_text(_panel_x + 15, _panel_y + 15, "LEGEND:");
    
    draw_set_color(c_orange);
    draw_text(_panel_x + 15, _panel_y + 40, "■ CPU Trace");
    
    draw_set_color(c_lime);
    draw_text(_panel_x + 15, _panel_y + 60, "■ GPU Trace");
    
    // Stats for the FOCUSED run
    draw_set_color(c_ltgray);
    draw_text(_panel_x + 15, _panel_y + 100, "LATEST RUN STATS:");
    
    if (!is_undefined(_run)) {
        draw_set_color(c_white);
        draw_text(_panel_x + 15, _panel_y + 130, "Backend: " + string_upper(_run.backend));
        draw_text(_panel_x + 15, _panel_y + 150, "Latency: " + string(_run.latency_ms) + " ms");
        draw_text(_panel_x + 15, _panel_y + 170, "Energy: " + string(_run.energy_joules) + " J");
    }
    
    // Analysis
    var _insight_y = _panel_y + 210;
    draw_set_color(c_ltgray);
    draw_text(_panel_x + 15, _insight_y, "ANALYSIS:");
    
    draw_set_color(c_white);
    draw_text_ext(_panel_x + 15, _insight_y + 25, "Compare the curves!\n\nCPU (Orange) is flatter but longer.\n\nGPU (Green) spikes high but finishes fast.", 18, _panel_w - 30);
}
