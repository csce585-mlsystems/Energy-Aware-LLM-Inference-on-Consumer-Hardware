/// @function draw_energy_graph(_x, _y, _width, _height)
/// @description Main dispatcher for the dashboard graphs
function draw_energy_graph(_x, _y, _width, _height) {
    // Force Centered Layout (Restoring original layout logic)
    var _screen_width = display_get_gui_width();
    var _screen_height = display_get_gui_height();
    
    _width = 800;
    _height = 400;
    var _panel_w = 250;
    var _gap = 20;
    var _total_w = _width + _gap + _panel_w;
    
    // Center the WHOLE assembly (Graph + Panel)
    _x = (_screen_width - _total_w) / 2;
    _y = (_screen_height - _height) / 2 - 50;

    // Draw Title based on tab (don't uncomment it back in)
	/*
    draw_set_halign(fa_center);
    draw_set_color(c_white);
    var _title = "Energy-Aware Inference Dashboard";
    if (global.current_tab == "draw_energy_vs_latency") _title = "Energy vs Latency Trade-off";
    if (global.current_tab == "ablation_studies") _title = "Ablation Study: CPU Threads";
    if (global.current_tab == "metrics_comparison") _title = "Overall Metrics Comparison";
    
    draw_text_transformed(display_get_gui_width()/2, 30, _title, 2, 2, 0);*/

    // Dispatch to correct renderer
    if (global.current_tab == "live_trace") {
        draw_live_trace(_x, _y, _width, _height);
    } else if (global.current_tab == "draw_energy_vs_latency") {
        draw_energy_vs_latency(_x, _y, _width, _height);
    } else if (global.current_tab == "ablation_studies") {
        draw_ablation_studies(_x, _y, _width, _height);
    } else if (global.current_tab == "metrics_comparison") {
        draw_metrics_comparison(_x, _y, _width, _height);
    }
}

/// @function draw_live_trace(_x, _y, _width, _height)
/// @description The original real-time power trace graph
function draw_live_trace(_x, _y, _width, _height) {
    if (is_undefined(global.energy_data)) {
        draw_text(_x, _y, "No Data Loaded");
        return;
    }
    
    var _runs = global.energy_data.runs;
    var _run = _runs[global.current_run_index];
    
    // Define max power for scaling
    var _max_watts = 250;
    
    // Background & Border
    draw_set_color(make_color_rgb(20, 20, 25));
    draw_set_alpha(0.9);
    draw_rectangle(_x, _y, _x + _width, _y + _height, false);
    draw_set_alpha(1.0);
    draw_set_color(c_dkgray);
    draw_rectangle(_x, _y, _x + _width, _y + _height, true);
    
    // Grid & Axes
    draw_set_color(c_gray);
    var _grid_steps = 5;
    for (var i = 0; i <= _grid_steps; i++) {
        var _grid_y = _y + (_height / _grid_steps) * i;
        draw_set_alpha(0.2);
        draw_line(_x, _grid_y, _x + _width, _grid_y);
        draw_set_alpha(1.0);
        var _watt_value = _max_watts - (_max_watts / _grid_steps) * i;
        draw_set_color(c_ltgray);
        draw_set_halign(fa_right);
        draw_text(_x - 10, _grid_y - 8, string(floor(_watt_value)) + "W");
    }
    
    var _time_steps = 4;
    for (var i = 0; i <= _time_steps; i++) {
        var _grid_x = _x + (_width / _time_steps) * i;
        draw_set_color(c_gray);
        draw_set_alpha(0.2);
        draw_line(_grid_x, _y, _grid_x, _y + _height);
        draw_set_alpha(1.0);
        var _time_sec = (_run.latency_ms / 1000) * (i / _time_steps);
        draw_set_color(c_ltgray);
        draw_set_halign(fa_center);
        draw_text(_grid_x, _y + _height + 10, string_format(_time_sec, 1, 1) + "s");
    }
    
    // Axis Labels
    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(_x + _width/2, _y + _height + 35, "Time (seconds)");
    draw_text_transformed(_x - 85, _y + _height/2, "Power (Watts)", 1, 1, 90);

    // Helper to draw trace
    var _draw_trace_line = function(_run_data, _color, _alpha, _x, _y, _width, _height, _max_watts) {
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
    
    // Draw Traces
    if (variable_global_exists("history_cpu") && !is_undefined(global.history_cpu)) 
        _draw_trace_line(global.history_cpu, c_orange, 0.6, _x, _y, _width, _height, _max_watts);
    if (variable_global_exists("history_gpu") && !is_undefined(global.history_gpu)) 
        _draw_trace_line(global.history_gpu, c_lime, 0.6, _x, _y, _width, _height, _max_watts);
    if (variable_global_exists("current_run") && !is_undefined(global.current_run)) {
        var _r = global.current_run;
        var _col = (_r.backend == "gpu") ? c_lime : c_orange;
        if (_r.backend == "Processing...") _col = c_aqua;
        _draw_trace_line(_r, _col, 1.0, _x, _y, _width, _height, _max_watts);
    }

    // Interactive Hover
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    if (_mx >= _x && _mx <= _x + _width && _my >= _y && _my <= _y + _height) {
        var _rel_x = _mx - _x;
        var _hover_ratio = _rel_x / _width;
        var _current_trace = [];
        if (!is_undefined(_run)) _current_trace = _run.power_trace;
        
        if (array_length(_current_trace) > 0) {
            var _hover_index = clamp(floor(_hover_ratio * (array_length(_current_trace) - 1)), 0, array_length(_current_trace) - 1);
            var _hover_val = _current_trace[_hover_index];
            var _hover_time = (_run.latency_ms / 1000) * _hover_ratio;
            
            draw_set_color(c_white); draw_set_alpha(0.5);
            draw_line(_x + _hover_ratio * _width, _y, _x + _hover_ratio * _width, _y + _height);
            draw_set_alpha(1.0);
            
            var _tip_w = 180; var _tip_h = 60;
            var _tip_x = _mx + 15; var _tip_y = _my - 30;
            
            // Smart Positioning: Flip to left if blocking right panel
            if (_tip_x + _tip_w > _x + _width) _tip_x = _mx - _tip_w - 15;
            if (_tip_y < 0) _tip_y = _my + 15;
            
            draw_set_color(c_black); draw_set_alpha(0.95);
            draw_rectangle(_tip_x, _tip_y, _tip_x + _tip_w, _tip_y + _tip_h, false);
            draw_set_alpha(1.0);
            draw_set_color(c_white); draw_set_alpha(0.8);
            draw_rectangle(_tip_x, _tip_y, _tip_x + _tip_w, _tip_y + _tip_h, true);
            draw_set_alpha(1.0);
            
            draw_set_halign(fa_left);
            draw_set_color(c_ltgray); draw_text(_tip_x + 10, _tip_y + 10, "Time:");
            draw_set_color(c_white); draw_text(_tip_x + 65, _tip_y + 10, string_format(_hover_time, 1, 2) + " s");
            draw_set_color(c_ltgray); draw_text(_tip_x + 10, _tip_y + 35, "Power:");
            var _pc = (_run.backend == "gpu") ? c_lime : c_orange;
            draw_set_color(_pc); draw_text(_tip_x + 65, _tip_y + 35, string_format(_hover_val, 1, 2) + " W");
        }
    }
    
    // Side Panel
    var _px = _x + _width + 20; var _py = _y; var _pw = 250;
    draw_set_color(make_color_rgb(30, 30, 35)); draw_rectangle(_px, _py, _px + _pw, _py + _height, false);
    draw_set_color(c_dkgray); draw_rectangle(_px, _py, _px + _pw, _py + _height, true);
    
    draw_set_halign(fa_left); draw_set_color(c_white); draw_text(_px + 15, _py + 15, "LEGEND:");
    draw_set_color(c_orange); draw_text(_px + 15, _py + 40, "■ CPU Trace");
    draw_set_color(c_lime); draw_text(_px + 15, _py + 60, "■ GPU Trace");
    
    draw_set_color(c_ltgray); draw_text(_px + 15, _py + 100, "LATEST RUN STATS:");
    
    var _show_stats = (variable_global_exists("user_has_run_inference") && global.user_has_run_inference && !is_undefined(_run));
    
    draw_set_color(c_white);
    if (_show_stats) {
        draw_text(_px + 15, _py + 130, "Backend: " + string_upper(_run.backend));
        draw_text(_px + 15, _py + 150, "Latency: " + string(_run.latency_ms) + " ms");
        draw_text(_px + 15, _py + 170, "Energy: " + string(_run.energy_joules) + " J");
    } else {
        draw_text(_px + 15, _py + 130, "Backend: -");
        draw_text(_px + 15, _py + 150, "Latency: 0 ms");
        draw_text(_px + 15, _py + 170, "Energy: 0 J");
    }
    
    draw_set_color(c_ltgray); draw_text(_px + 15, _py + 210, "ANALYSIS:");
    
    draw_set_color(c_ltgray); draw_text(_px + 15, _py + 210, "ANALYSIS:");
    
    var _analysis_text = "Press 'Run CPU' or 'Run GPU'\nto generate analysis.";
    
    // Only show analysis if user has actively run inference
    if (variable_global_exists("user_has_run_inference") && global.user_has_run_inference && !is_undefined(_run)) {
        if (_run.backend == "Processing...") {
            _analysis_text = "Running Inference...\n\n(Waiting for server)";
        } else {
            _analysis_text = get_live_trace_insight(_run);
        }
    }
    
    draw_set_color(c_white); draw_text_ext(_px + 15, _py + 235, _analysis_text, 18, _pw - 30);
}

/// @function draw_energy_vs_latency(_x, _y, _width, _height)
/// @function draw_energy_vs_latency(_x, _y, _width, _height)
function draw_energy_vs_latency(_x, _y, _width, _height) {
    // Background
    draw_set_color(make_color_rgb(20, 20, 25)); draw_rectangle(_x, _y, _x + _width, _y + _height, false);
    draw_set_color(c_dkgray); draw_rectangle(_x, _y, _x + _width, _y + _height, true);
    
    // Axes
    draw_set_color(c_white);
    draw_line(_x, _y + _height, _x + _width, _y + _height); // X
    draw_line(_x, _y, _x, _y + _height); // Y
    
    draw_set_halign(fa_center); draw_text(_x + _width/2, _y + _height + 20, "Latency (ms)");
    draw_text_transformed(_x - 40, _y + _height/2, "Energy (Joules)", 1, 1, 90);
    
    // Add Scales
    var _grid_steps = 5;
    var _max_lat_scale = 10000; // Placeholder until data loaded
    var _max_eng_scale = 200;
    
    // Find Max for scaling first
    if (array_length(global.all_runs) > 0) {
        var _max_l = 0; var _max_e = 0;
        for (var i = 0; i < array_length(global.all_runs); i++) {
            if (global.all_runs[i].latency_ms > _max_l) _max_l = global.all_runs[i].latency_ms;
            if (global.all_runs[i].energy_joules > _max_e) _max_e = global.all_runs[i].energy_joules;
        }
        _max_lat_scale = _max_l * 1.1;
        _max_eng_scale = _max_e * 1.1;
    }
    
    // Draw Grid & Labels
    draw_set_halign(fa_center); draw_set_color(c_gray);
    for (var i = 0; i <= _grid_steps; i++) {
        // X Axis (Latency)
        var _gx = _x + (_width / _grid_steps) * i;
        draw_set_alpha(0.2); draw_line(_gx, _y, _gx, _y + _height); draw_set_alpha(1.0);
        var _val_x = (_max_lat_scale / _grid_steps) * i;
        draw_text(_gx, _y + _height + 5, string_format(_val_x, 1, 0));
        
        // Y Axis (Energy)
        var _gy = _y + (_height / _grid_steps) * i;
        draw_set_alpha(0.2); draw_line(_x, _gy, _x + _width, _gy); draw_set_alpha(1.0);
        var _val_y = _max_eng_scale - (_max_eng_scale / _grid_steps) * i;
        draw_text(_x - 25, _gy - 8, string_format(_val_y, 1, 0));
    }
    
    // Use Real Data from global.all_runs
    if (array_length(global.all_runs) == 0) {
        draw_text(_x + _width/2, _y + _height/2, "No Data Yet. Run Inference!");
        return;
    }
    
    var _max_lat = 10; // Dynamic scaling
    var _max_eng = 10;
    
    // 1. Find Max Values for Scaling
    for (var i = 0; i < array_length(global.all_runs); i++) {
        var _r = global.all_runs[i];
        if (_r.latency_ms > _max_lat) _max_lat = _r.latency_ms;
        if (_r.energy_joules > _max_eng) _max_eng = _r.energy_joules;
    }
    _max_lat *= 1.1; // Add padding
    _max_eng *= 1.1;
    
    // 2. Plot Points with Hover Detection
    var _mouse_x = device_mouse_x_to_gui(0);
    var _mouse_y = device_mouse_y_to_gui(0);
    var _hovering_point = -1;
    
    for (var i = 0; i < array_length(global.all_runs); i++) {
        var _r = global.all_runs[i];
        
        var _px = _x + (_r.latency_ms / _max_lat) * _width;
        var _py = _y + _height - (_r.energy_joules / _max_eng) * _height;
        
        // Check hover
        var _dist = point_distance(_mouse_x, _mouse_y, _px, _py);
        var _is_hover = (_dist < 10);
        
        if (_is_hover) _hovering_point = i;
        
        var _col = (_r.backend == "gpu") ? c_lime : c_orange;
        draw_set_color(_col);
        draw_circle(_px, _py, _is_hover ? 8 : 6, false);
        
        // Highlight outline on hover
        if (_is_hover) {
            draw_set_color(c_white);
            draw_circle(_px, _py, 9, true);
        }
    }
    
    // Render Tooltip (after all points for z-order)
    if (_hovering_point != -1) {
        var _r = global.all_runs[_hovering_point];
        var _px = _x + (_r.latency_ms / _max_lat) * _width;
        var _py = _y + _height - (_r.energy_joules / _max_eng) * _height;
        
        var _tooltip_text = string_upper(_r.backend) + " | " + string_format(_r.latency_ms, 1, 1) + "ms | " + string_format(_r.energy_joules, 1, 2) + "J";
        var _tooltip_w = string_width(_tooltip_text) + 16;
        var _tooltip_h = 32;
        var _tooltip_x = _px + 15;
        var _tooltip_y = _py - _tooltip_h - 5;
        
        // Keep on screen
        if (_tooltip_x + _tooltip_w > _x + _width) _tooltip_x = _px - _tooltip_w - 15;
        if (_tooltip_y < _y) _tooltip_y = _py + 10;
        
        // Draw tooltip box
        draw_set_color(make_color_rgb(30, 30, 40));
        draw_rectangle(_tooltip_x, _tooltip_y, _tooltip_x + _tooltip_w, _tooltip_y + _tooltip_h, false);
        draw_set_color(c_white);
        draw_rectangle(_tooltip_x, _tooltip_y, _tooltip_x + _tooltip_w, _tooltip_y + _tooltip_h, true);
        
        draw_set_halign(fa_left);
        draw_set_color(c_white);
        draw_text(_tooltip_x + 8, _tooltip_y + 8, _tooltip_text);
    }
    
    // Legend
    draw_set_halign(fa_left);
    draw_set_color(c_orange); draw_text(_x + _width - 150, _y + 20, "■ CPU Run");
    draw_set_color(c_lime); draw_text(_x + _width - 150, _y + 40, "■ GPU Run");
    
    // Side Panel Analysis
    var _px = _x + _width + 20; var _py = _y; var _pw = 250;
    draw_set_color(make_color_rgb(30, 30, 35)); draw_rectangle(_px, _py, _px + _pw, _py + _height, false);
    draw_set_color(c_dkgray); draw_rectangle(_px, _py, _px + _pw, _py + _height, true);
    
    draw_set_color(c_ltgray); draw_text(_px + 15, _py + 15, "TRADE-OFF ANALYSIS:");
    draw_set_color(c_white);
    var _msg = "This chart shows the Pareto Frontier.\n\n";
    _msg += "• Bottom-Left: Ideal (Fast & Efficient)\n";
    _msg += "• Top-Right: Inefficient (Slow & Power Hungry)\n\n";
    _msg += "Notice how GPU runs (Green) cluster towards the bottom-left compared to CPU runs (Orange).";
    draw_text_ext(_px + 15, _py + 45, _msg, 18, _pw - 30);
} // <--- closing brace added here

/// @function draw_ablation_studies(_x, _y, _width, _height)
function draw_ablation_studies(_x, _y, _width, _height) {
    // Background
    draw_set_color(make_color_rgb(20, 20, 25)); draw_rectangle(_x, _y, _x + _width, _y + _height, false);
    draw_set_color(c_dkgray); draw_rectangle(_x, _y, _x + _width, _y + _height, true);
    
    // 1. Filter Data based on Mode
    // Mode 0: Layers (gpu-l0, gpu-l11, gpu-l22)
    // Mode 1: Threads (cpu-t1, cpu-t4, cpu-t8)
    // Mode 2: Batch (gpu-b128, gpu-b512, gpu-b1024)
    
    var _points = [];
    var _x_label = "";
    var _title = "";
    
    // Helper to find avg latency for a run_id prefix
    var _find_avg = function(_prefix) {
        var _sum = 0; var _count = 0;
        for (var i = 0; i < array_length(global.all_runs); i++) {
            var _r = global.all_runs[i];
            // Check if run_id starts with prefix (simple string check)
            if (string_pos(_prefix, _r.run_id) == 1) {
                _sum += _r.latency_ms;
                _count++;
            }
        }
        return (_count > 0) ? (_sum / _count) : 0;
    };
    
    if (global.ablation_mode == 0) {
        _title = "GPU Layer Offloading (Click to Switch)";
        _x_label = "Layers Offloaded";
        if (_find_avg("gpu-l0") > 0) array_push(_points, {x: 0, y: _find_avg("gpu-l0")});
        if (_find_avg("gpu-l11") > 0) array_push(_points, {x: 11, y: _find_avg("gpu-l11")});
        if (_find_avg("gpu-l22") > 0) array_push(_points, {x: 22, y: _find_avg("gpu-l22")});
    } else if (global.ablation_mode == 1) {
        _title = "CPU Thread Scaling (Click to Switch)";
        _x_label = "Threads";
        if (_find_avg("cpu-t1") > 0) array_push(_points, {x: 1, y: _find_avg("cpu-t1")});
        if (_find_avg("cpu-t4") > 0) array_push(_points, {x: 4, y: _find_avg("cpu-t4")});
        if (_find_avg("cpu-t8") > 0) array_push(_points, {x: 8, y: _find_avg("cpu-t8")});
    } else {
        _title = "Batch Size Scaling (Click to Switch)";
        _x_label = "Batch Size";
        if (_find_avg("gpu-b128") > 0) array_push(_points, {x: 128, y: _find_avg("gpu-b128")});
        if (_find_avg("gpu-b512") > 0) array_push(_points, {x: 512, y: _find_avg("gpu-b512")});
        if (_find_avg("gpu-b1024") > 0) array_push(_points, {x: 1024, y: _find_avg("gpu-b1024")});
    }
    
    // Title
    draw_set_halign(fa_center); draw_set_color(c_white);
    draw_text(_x + _width/2, _y + 20, _title);
    
    // Click to Switch Logic
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);
    if (mouse_check_button_pressed(mb_left)) {
        if (_mx > _x && _mx < _x + _width && _my > _y && _my < _y + _height) {
            global.ablation_mode = (global.ablation_mode + 1) % 3;
        }
    }
    
    if (array_length(_points) == 0) {
        draw_text(_x + _width/2, _y + _height/2, "No Data for this Study.");
    } else {
        // Draw Graph
        var _max_y = 0; var _max_x = 0;
        for (var i = 0; i < array_length(_points); i++) {
            if (_points[i].y > _max_y) _max_y = _points[i].y;
            if (_points[i].x > _max_x) _max_x = _points[i].x;
        }
        _max_y *= 1.2;
        if (_max_x == 0) _max_x = 10; // Prevent div by zero
        
        // Axes
        draw_set_color(c_white);
        draw_line(_x + 50, _y + _height - 50, _x + _width - 20, _y + _height - 50); // X
        draw_line(_x + 50, _y + 50, _x + 50, _y + _height - 50); // Y
        
        draw_text(_x + _width/2, _y + _height - 20, _x_label);
        draw_text_transformed(_x + 20, _y + _height/2, "Latency (ms)", 1, 1, 90);
        
        // Plot Lines & Points
        draw_set_color(c_aqua);
        var _hover_point = -1;
        
        for (var i = 0; i < array_length(_points); i++) {
            var _p = _points[i];
            var _px = _x + 50 + (_p.x / _max_x) * (_width - 100);
            var _py = (_y + _height - 50) - (_p.y / _max_y) * (_height - 100);
            
            // Check hover
            if (point_distance(_mx, _my, _px, _py) < 10) {
                _hover_point = i;
            }
            
            draw_circle(_px, _py, (_hover_point == i) ? 8 : 6, false);
            if (_hover_point == i) {
                draw_set_color(c_white); draw_circle(_px, _py, 9, true); draw_set_color(c_aqua);
            }
            
            draw_text(_px, _py - 20, string(floor(_p.y)));
            
            if (i > 0) {
                var _prev = _points[i-1];
                var _prev_x = _x + 50 + (_prev.x / _max_x) * (_width - 100);
                var _prev_y = (_y + _height - 50) - (_prev.y / _max_y) * (_height - 100);
                draw_line(_prev_x, _prev_y, _px, _py);
            }
            
            // X Labels
            draw_text(_px, _y + _height - 40, string(_p.x));
        }
        
        // Draw Tooltip if hovering
        if (_hover_point != -1) {
            var _p = _points[_hover_point];
            var _px = _x + 50 + (_p.x / _max_x) * (_width - 100);
            var _py = (_y + _height - 50) - (_p.y / _max_y) * (_height - 100);
            
            var _tt_text = _x_label + ": " + string(_p.x) + "\nLatency: " + string_format(_p.y, 1, 1) + " ms";
            var _tt_w = string_width(_tt_text) + 20;
            var _tt_h = string_height(_tt_text) + 20;
            var _tt_x = _px + 15;
            var _tt_y = _py - _tt_h - 10;
            
            // Keep on screen
            if (_tt_x + _tt_w > _x + _width) _tt_x = _px - _tt_w - 15;
            if (_tt_y < _y) _tt_y = _py + 15;
            
            draw_set_color(make_color_rgb(30, 30, 40));
            draw_rectangle(_tt_x, _tt_y, _tt_x + _tt_w, _tt_y + _tt_h, false);
            draw_set_color(c_white);
            draw_rectangle(_tt_x, _tt_y, _tt_x + _tt_w, _tt_y + _tt_h, true);
            
            draw_set_halign(fa_left);
            draw_text(_tt_x + 10, _tt_y + 10, _tt_text);
        }
    }
    
    // Side Panel Analysis
    var _px = _x + _width + 20; var _py = _y; var _pw = 250;
    draw_set_color(make_color_rgb(30, 30, 35)); draw_rectangle(_px, _py, _px + _pw, _py + _height, false);
    draw_set_color(c_dkgray); draw_rectangle(_px, _py, _px + _pw, _py + _height, true);
    
    draw_set_halign(fa_left); // Reset alignment
    draw_set_color(c_ltgray); draw_text(_px + 15, _py + 15, "INSIGHTS:");
    draw_set_color(c_white);
    
    var _msg = get_ablation_insight(global.ablation_mode);
    draw_text_ext(_px + 15, _py + 45, _msg, 18, _pw - 30);
}

/// @function draw_metrics_comparison(_x, _y, _width, _height)
function draw_metrics_comparison(_x, _y, _width, _height) {
    // Background
    draw_set_color(make_color_rgb(20, 20, 25)); draw_rectangle(_x, _y, _x + _width, _y + _height, false);
    draw_set_color(c_dkgray); draw_rectangle(_x, _y, _x + _width, _y + _height, true);
    
    // Y-Axis Scale (Latency)
    draw_set_color(c_white); draw_line(_x, _y, _x, _y + _height); // Y-axis line
    draw_set_halign(fa_right); draw_set_color(c_gray);
    draw_text_transformed(_x - 20, _y + _height/2, "Latency (ms)", 1, 1, 90);
    
    // Calculate Averages
    var _cpu_lat_sum = 0; var _cpu_eng_sum = 0; var _cpu_count = 0;
    var _gpu_lat_sum = 0; var _gpu_eng_sum = 0; var _gpu_count = 0;
    
    for (var i = 0; i < array_length(global.all_runs); i++) {
        var _r = global.all_runs[i];
        if (_r.backend == "cpu") { 
            _cpu_lat_sum += _r.latency_ms; 
            _cpu_eng_sum += _r.energy_joules;
            _cpu_count++; 
        }
        if (_r.backend == "gpu") { 
            _gpu_lat_sum += _r.latency_ms; 
            _gpu_eng_sum += _r.energy_joules;
            _gpu_count++; 
        }
    }
    
    var _cpu_avg = (_cpu_count > 0) ? (_cpu_lat_sum / _cpu_count) : 0;
    var _gpu_avg = (_gpu_count > 0) ? (_gpu_lat_sum / _gpu_count) : 0;
    
    if (_cpu_count == 0 && _gpu_count == 0) {
        draw_set_halign(fa_center); draw_text(_x + _width/2, _y + _height/2, "No Data Yet.");
        return;
    }
    
    var _max_val = max(_cpu_avg, _gpu_avg, 100) * 1.2; // Scale based on max + padding
    
    // Draw Y-Axis Grid
    var _steps = 5;
    for (var i = 0; i <= _steps; i++) {
        var _gy = _y + _height - (_height / _steps) * i;
        var _gval = (_max_val / _steps) * i;
        draw_set_alpha(0.2); draw_set_color(c_gray); draw_line(_x, _gy, _x + _width, _gy); draw_set_alpha(1.0);
        draw_set_color(c_ltgray); draw_text(_x - 10, _gy - 8, string_format(_gval, 1, 0));
    }
    
    var _bar_w = 100;
    var _gap = 200;
    var _start_x = _x + _width/2 - _gap/2 - _bar_w;
    
    var _mouse_x = device_mouse_x_to_gui(0);
    var _mouse_y = device_mouse_y_to_gui(0);
    var _hover_cpu = false;
    var _hover_gpu = false;
    
    // CPU Bar
    // CPU Bar
    if (_cpu_count > 0) {
        var _cpu_h = (_cpu_avg / _max_val) * _height;
        var _cpu_y1 = _y + _height - _cpu_h;
        var _cpu_y2 = _y + _height;
        
        // Check hover
        _hover_cpu = (_mouse_x >= _start_x && _mouse_x <= _start_x + _bar_w && _mouse_y >= _cpu_y1 && _mouse_y <= _cpu_y2);
        
        draw_set_color(_hover_cpu ? make_color_rgb(255, 200, 100) : c_orange);
        draw_rectangle(_start_x, _cpu_y1, _start_x + _bar_w, _cpu_y2, false);
        
        if (_hover_cpu) {
            draw_set_color(c_white);
            draw_rectangle(_start_x, _cpu_y1, _start_x + _bar_w, _cpu_y2, true);
        }
        
        draw_set_color(c_white); draw_set_halign(fa_center);
        draw_text(_start_x + _bar_w/2, _y + _height + 10, "CPU Avg");
        draw_text(_start_x + _bar_w/2, _y + _height - _cpu_h - 20, string_format(_cpu_avg, 1, 0) + "ms");
    }
    
    // GPU Bar
    var _gpu_x = _start_x + _bar_w + _gap;
    if (_gpu_count > 0) {
        var _gpu_h = (_gpu_avg / _max_val) * _height;
        var _gpu_y1 = _y + _height - _gpu_h;
        var _gpu_y2 = _y + _height;
        
        // Check hover
        _hover_gpu = (_mouse_x >= _gpu_x && _mouse_x <= _gpu_x + _bar_w && _mouse_y >= _gpu_y1 && _mouse_y <= _gpu_y2);
        
        draw_set_color(_hover_gpu ? make_color_rgb(100, 255, 150) : c_lime);
        draw_rectangle(_gpu_x, _gpu_y1, _gpu_x + _bar_w, _gpu_y2, false);
        
        if (_hover_gpu) {
            draw_set_color(c_white);
            draw_rectangle(_gpu_x, _gpu_y1, _gpu_x + _bar_w, _gpu_y2, true);
        }
        
        draw_set_color(c_white);
        draw_text(_gpu_x + _bar_w/2, _y + _height + 10, "GPU Avg");
        draw_text(_gpu_x + _bar_w/2, _y + _height - _gpu_h - 20, string_format(_gpu_avg, 1, 0) + "ms");
    }
    
    // (Tooltips moved to end)
    
    // Speedup Text
    if (_cpu_count > 0 && _gpu_count > 0 && _gpu_avg > 0) {
        var _speedup = _cpu_avg / _gpu_avg;
        
        var _cpu_avg_eng = _cpu_eng_sum / _cpu_count;
        var _gpu_avg_eng = _gpu_eng_sum / _gpu_count;
        var _savings = ((_cpu_avg_eng - _gpu_avg_eng) / _cpu_avg_eng) * 100;
        
        draw_set_halign(fa_center);
        draw_text_transformed(_x + _width/2, _y + 40, string_format(_speedup, 1, 1) + "x Speedup with GPU", 1.5, 1.5, 0);
        
        var _col = (_savings > 0) ? c_lime : c_orange;
        draw_set_color(_col);
        draw_text_transformed(_x + _width/2, _y + 70, string_format(_savings, 1, 0) + "% Energy Savings", 1.2, 1.2, 0);
    }
    
    // Side Panel Analysis
    var _px = _x + _width + 20; var _py = _y; var _pw = 250;
    draw_set_color(make_color_rgb(30, 30, 35)); draw_rectangle(_px, _py, _px + _pw, _py + _height, false);
    draw_set_color(c_dkgray); draw_rectangle(_px, _py, _px + _pw, _py + _height, true);
    
    draw_set_halign(fa_left); // <--- FIX: Reset alignment to left!
    draw_set_color(c_ltgray); draw_text(_px + 15, _py + 15, "METRICS SUMMARY:");
    draw_set_color(c_white);
    
    draw_set_color(c_ltgray); draw_text(_px + 15, _py + 15, "METRICS SUMMARY:");
    draw_set_color(c_white);
    
    var _msg2 = get_metrics_insight(_cpu_count, _gpu_count, _speedup, _savings);
    
    draw_text_ext(_px + 15, _py + 45, _msg2, 18, _pw - 30);
    
    // Render Tooltips (Last for Z-Order)
    if (_hover_cpu) {
        var _tooltip_text = "CPU Average: " + string_format(_cpu_avg, 1, 2) + " ms (" + string(_cpu_count) + " runs)";
        var _tooltip_w = string_width(_tooltip_text) + 16;
        var _tooltip_h = 32;
        var _tooltip_x = _start_x + _bar_w + 10;
        var _tooltip_y = _mouse_y - 16;
        
        // Keep on screen
        if (_tooltip_x + _tooltip_w > _px) _tooltip_x = _start_x - _tooltip_w - 10; // Flip left if hitting panel
        
        draw_set_color(make_color_rgb(30, 30, 40));
        draw_rectangle(_tooltip_x, _tooltip_y, _tooltip_x + _tooltip_w, _tooltip_y + _tooltip_h, false);
        draw_set_color(c_white);
        draw_rectangle(_tooltip_x, _tooltip_y, _tooltip_x + _tooltip_w, _tooltip_y + _tooltip_h, true);
        
        draw_set_halign(fa_left);
        draw_text(_tooltip_x + 8, _tooltip_y + 8, _tooltip_text);
    }
    
    if (_hover_gpu) {
        var _tooltip_text = "GPU Average: " + string_format(_gpu_avg, 1, 2) + " ms (" + string(_gpu_count) + " runs)";
        var _tooltip_w = string_width(_tooltip_text) + 16;
        var _tooltip_h = 32;
        var _tooltip_x = _gpu_x + _bar_w + 10;
        var _tooltip_y = _mouse_y - 16;
        
        // Keep on screen
        if (_tooltip_x + _tooltip_w > _px) _tooltip_x = _gpu_x - _tooltip_w - 10; // Flip left if hitting panel
        
        draw_set_color(make_color_rgb(30, 30, 40));
        draw_rectangle(_tooltip_x, _tooltip_y, _tooltip_x + _tooltip_w, _tooltip_y + _tooltip_h, false);
        draw_set_color(c_white);
        draw_rectangle(_tooltip_x, _tooltip_y, _tooltip_x + _tooltip_w, _tooltip_y + _tooltip_h, true);
        
        draw_set_halign(fa_left);
        draw_text(_tooltip_x + 8, _tooltip_y + 8, _tooltip_text);
    }
}
