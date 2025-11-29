/// @function draw_energy_graph(_x, _y, _width, _height)
/// @description Draws the power trace for the current run.

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
    
    // Background
    draw_set_color(c_black);
    draw_set_alpha(0.8);
    draw_rectangle(_x, _y, _x + _width, _y + _height, false);
    draw_set_alpha(1.0);
    
    // Grid
    draw_set_color(c_dkgray);
    draw_line(_x, _y + _height/2, _x + _width, _y + _height/2); // Midline
    
    // Plot Line
    // Find max power for scaling (e.g., 200W)
    var _max_watts = 250; 
    
    if (_run.backend == "gpu") draw_set_color(c_lime);
    else draw_set_color(c_aqua);
    
    draw_primitive_begin(pr_linestrip);
    for (var i = 0; i < _count; i++) {
        var _val = _trace[i];
        
        var _px = _x + (i / (_count - 1)) * _width;
        var _py = _y + _height - (_val / _max_watts) * _height;
        
        // Clamp
        if (_py < _y) _py = _y;
        
        draw_vertex(_px, _py);
    }
    draw_primitive_end();
    
    // Draw Info
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_text(_x + 10, _y + 10, "Run ID: " + _run.run_id);
    draw_text(_x + 10, _y + 30, "Backend: " + string_upper(_run.backend));
    draw_text(_x + 10, _y + 50, "Latency: " + string(_run.latency_ms) + " ms");
    draw_text(_x + 10, _y + 70, "Energy: " + string(_run.energy_joules) + " J");
    
    // Draw "Race to Sleep" Badge if GPU
    if (_run.backend == "gpu") {
        draw_set_color(c_yellow);
        draw_text(_x + _width - 150, _y + 10, "⚡ RACE TO SLEEP");
    }
}
