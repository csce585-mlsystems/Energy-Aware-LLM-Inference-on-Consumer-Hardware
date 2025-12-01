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
    else if (_run_id == "gpu-10") {
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

function sort_by_edp(_a, _b) {
    var _edp_a = calculate_edp(_a);
    var _edp_b = calculate_edp(_b);
    return _edp_a - _edp_b; // Ascending (lower is better)
}

function draw_ranking_tab() {
    // Match the graph area: x=50, y=100, w=800, h=400
    // But now centered!
    var _total_w = 1200; // Increased to 1200 for maximum spacing
    var _total_h = 400;
    
    var _screen_width = display_get_gui_width();
    var _screen_height = display_get_gui_height();
    
    var _x = (_screen_width - _total_w) / 2;
    var _y = (_screen_height - _total_h) / 2 - 50; // Match the offset in GraphRenderer
    
    // Split: List (65%) | Panel (35%)
    var _list_w = 750; // Increased to 750
    var _gap = 30;
    var _panel_x = _x + _list_w + _gap;
    var _panel_w = _total_w - _list_w - _gap;
    
    // Background for the whole area (optional, matches graph look)
    draw_set_color(make_color_rgb(20, 20, 25));
    draw_rectangle(_x, _y, _x + _total_w, _y + _total_h, false);
    draw_set_color(c_dkgray);
    draw_rectangle(_x, _y, _x + _total_w, _y + _total_h, true);
    
    // --- LEFT: Ranking List ---
    draw_set_color(c_white);
    draw_text(_x + 10, _y + 10, "Ranking (Lowest EDP is Best)");
    
    // List Headers
    var _header_y = _y + 40;
    draw_set_color(c_ltgray);
    draw_text(_x + 10, _header_y, "ID");
    draw_text(_x + 150, _header_y, "Backend"); // +140
    draw_text(_x + 300, _header_y, "Lat(ms)"); // +150
    draw_text(_x + 450, _header_y, "Eng(J)"); // +150
    draw_text(_x + 600, _header_y, "EDP"); // +150
    draw_text(_x + 700, _header_y, "Select"); // +100
    
    var _list_y = _header_y + 25;
    
    // Create sorted list
    var _runs = [];
    if (array_length(global.all_runs) > 0) {
        array_copy(_runs, 0, global.all_runs, 0, array_length(global.all_runs));
        array_sort(_runs, sort_by_edp);
    }
    
    // Scroll/Limit (Show top 10 to fit with note)
    var _count = min(array_length(_runs), 10);
    
    for (var i = 0; i < _count; i++) {
        var _r = _runs[i];
        var _edp = calculate_edp(_r);
        
        draw_set_color(c_white);
        draw_text(_x + 10, _list_y, _r.run_id);
        draw_text(_x + 150, _list_y, _r.backend);
        draw_text(_x + 300, _list_y, string(round(_r.latency_ms)));
        draw_text(_x + 450, _list_y, string_format(_r.energy_joules, 0, 2));
        
        // Highlight 0 EDP
        if (_edp == 0) draw_set_color(c_red);
        draw_text(_x + 600, _list_y, string_format(_edp, 0, 2) + (_edp == 0 ? "*" : ""));
        draw_set_color(c_white);
        
        // Selection Logic
        var _btn_x = _x + 700;
        var _btn_w = 60;
        var _btn_h = 20;
        
        var _is_sel_1 = (global.compare_run_1 == _r);
        var _is_sel_2 = (global.compare_run_2 == _r);
        
        if (_is_sel_1) draw_set_color(c_orange);
        else if (_is_sel_2) draw_set_color(c_aqua);
        else draw_set_color(c_dkgray);
        
        draw_rectangle(_btn_x, _list_y, _btn_x + _btn_w, _list_y + _btn_h, false);
        
        draw_set_color(c_white);
        draw_set_halign(fa_center);
        if (_is_sel_1) draw_text(_btn_x + _btn_w/2, _list_y + 2, "Run 1");
        else if (_is_sel_2) draw_text(_btn_x + _btn_w/2, _list_y + 2, "Run 2");
        else draw_text(_btn_x + _btn_w/2, _list_y + 2, "Sel");
        draw_set_halign(fa_left); // Reset
        
        // Interaction
        if (mouse_check_button_pressed(mb_left)) {
            // Button Click (Selection)
            if (mouse_x >= _btn_x && mouse_x <= _btn_x + _btn_w && mouse_y >= _list_y && mouse_y <= _list_y + _btn_h) {
                if (_is_sel_1) global.compare_run_1 = undefined;
                else if (_is_sel_2) global.compare_run_2 = undefined;
                else {
                    if (is_undefined(global.compare_run_1)) global.compare_run_1 = _r;
                    else if (is_undefined(global.compare_run_2)) global.compare_run_2 = _r;
                    else {
                        global.compare_run_1 = global.compare_run_2;
                        global.compare_run_2 = _r;
                    }
                }
            }
            // Row Click (Explanation) - Check if clicked anywhere in the row BUT not the button
            else if (mouse_x >= _x && mouse_x <= _x + _list_w && mouse_y >= _list_y && mouse_y <= _list_y + 20) {
                 global.explained_run = _r;
            }
        }
        
        _list_y += 25;
    }
    
    // Explanation for EDP = 0
    draw_set_color(c_gray);
    draw_text(_x + 10, _list_y + 10, "* EDP = 0 indicates missing energy data (0 Joules measured).");
    
    // --- RIGHT: Comparison Panel & Explanation ---
    // Split Right Panel: Top 60% Comparison, Bottom 40% Explanation
    var _comp_h = _total_h * 0.6;
    var _expl_h = _total_h * 0.4;
    var _expl_y = _y + _comp_h;
    
    draw_comparison_panel(_panel_x, _y, _panel_w, _comp_h);
    draw_code_explanation_panel(_panel_x, _expl_y, _panel_w, _expl_h);
}
