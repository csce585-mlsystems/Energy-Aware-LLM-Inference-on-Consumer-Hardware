function get_run_id_explanation(_run_id) {
    var _expl = "Unknown configuration.";
    
    if (string_pos("cpu-t", _run_id) == 1) {
        var _threads = string_delete(_run_id, 1, 5);
        _expl = "CPU Backend with " + _threads + " threads.\nMore threads typically improve performance up to a limit.";
    }
    else if (string_pos("gpu-l", _run_id) == 1) {
        var _layers = string_delete(_run_id, 1, 5);
        _expl = "GPU Backend with " + _layers + " layers offloaded.\nOffloading more layers to GPU reduces CPU load and latency.";
    }
    else if (string_pos("gpu-b", _run_id) == 1) {
        var _batch = string_delete(_run_id, 1, 5);
        _expl = "GPU Backend with Batch Size " + _batch + ".\nLarger batches increase throughput but may increase latency per token.";
    }
    else if (string_pos("power_only", _run_id) == 1) {
        _expl = "Baseline Power Measurement.\nNo inference running, just measuring idle/background power.";
    }
    else if (_run_id == "gpu-10") { // Handle the specific case seen in screenshot if needed, or generic
         _expl = "GPU Backend Run.";
    }
    
    return _expl;
}

function draw_code_explanation_panel(_x, _y, _w, _h) {
    draw_set_color(c_dkgray);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    
    draw_set_color(c_white);
    draw_text(_x + 10, _y + 10, "Configuration Details:");
    
    if (is_undefined(global.explained_run)) {
        draw_set_color(c_gray);
        draw_text_ext(_x + 10, _y + 35, "Click a row to see details about its configuration code.", 18, _w - 20);
    } else {
        var _r = global.explained_run;
        draw_set_color(c_aqua);
        draw_text(_x + 10, _y + 35, _r.run_id);
        
        draw_set_color(c_ltgray);
        var _text = get_run_id_explanation(_r.run_id);
        draw_text_ext(_x + 10, _y + 60, _text, 18, _w - 20);
    }
}
