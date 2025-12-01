function draw_comparison_panel(_x, _y, _w, _h) {
    // Background is already drawn by Ranking.gml, but we can keep the inner border if we want
    // or just draw the content. Let's keep it simple.
    
    draw_set_color(c_white);
    draw_text(_x + 10, _y + 10, "Comparison View");
    
    var _r1 = global.compare_run_1;
    var _r2 = global.compare_run_2;
    
    if (is_undefined(_r1) || is_undefined(_r2)) {
        draw_text_ext(_x + 10, _y + 40, "Select two runs from the list to compare.", 20, _w - 20);
        return;
    }
    
    // Layout for narrow panel
    var _col1_x = _x + 120; // Shifted right
    var _col2_x = _x + 280; // Shifted right
    var _row_h = 30; // Reduced vertical space (was 40)
    var _cur_y = _y + 50;
    
    // Headers (Run IDs)
    draw_set_color(c_orange);
    draw_text(_col1_x, _cur_y, "Run 1");
    draw_set_color(c_aqua);
    draw_text(_col2_x, _cur_y, "Run 2");
    
    _cur_y += 20;
    draw_set_color(c_ltgray);
    draw_set_font(-1); // Default font
    draw_text(_col1_x, _cur_y, _r1.run_id);
    draw_text(_col2_x, _cur_y, _r2.run_id);
    
    _cur_y += _row_h;
    
    // Helper to draw row
    var _draw_row = function(_label, _val1, _val2, _better_idx, _y_pos, _x_start, _c1, _c2) {
        draw_set_color(c_white);
        draw_text(_x_start + 10, _y_pos, _label);
        
        // Value 1
        if (_better_idx == 1) draw_set_color(c_lime); else draw_set_color(c_ltgray);
        draw_text(_c1, _y_pos + 20, _val1);
        
        // Value 2
        if (_better_idx == 2) draw_set_color(c_lime); else draw_set_color(c_ltgray);
        draw_text(_c2, _y_pos + 20, _val2);
    };
    
    // Backend
    draw_set_color(c_white); draw_text(_x + 10, _cur_y, "Backend");
    draw_set_color(c_ltgray);
    draw_text(_col1_x, _cur_y + 20, _r1.backend);
    draw_text(_col2_x, _cur_y + 20, _r2.backend);
    _cur_y += _row_h + 15; // Reduced spacing
    
    // Latency
    var _better_lat = 0;
    if (_r1.latency_ms < _r2.latency_ms) _better_lat = 1;
    else if (_r2.latency_ms < _r1.latency_ms) _better_lat = 2;
    _draw_row("Latency (ms)", string(round(_r1.latency_ms)), string(round(_r2.latency_ms)), _better_lat, _cur_y, _x, _col1_x, _col2_x);
    _cur_y += _row_h + 15; // Reduced spacing
    
    // Energy
    var _better_eng = 0;
    if (_r1.energy_joules < _r2.energy_joules) _better_eng = 1;
    else if (_r2.energy_joules < _r1.energy_joules) _better_eng = 2;
    _draw_row("Energy (J)", string_format(_r1.energy_joules, 0, 2), string_format(_r2.energy_joules, 0, 2), _better_eng, _cur_y, _x, _col1_x, _col2_x);
    _cur_y += _row_h + 15; // Reduced spacing
    
    // EDP
    var _edp1 = calculate_edp(_r1);
    var _edp2 = calculate_edp(_r2);
    var _better_edp = 0;
    if (_edp1 < _edp2) _better_edp = 1;
    else if (_edp2 < _edp1) _better_edp = 2;
    _draw_row("EDP (J*s)", string_format(_edp1, 0, 2), string_format(_edp2, 0, 2), _better_edp, _cur_y, _x, _col1_x, _col2_x);
    
    // Summary/Winner
    _cur_y += _row_h + 30; // Reduced spacing
    draw_set_color(c_white);
    draw_text(_x + 10, _cur_y, "Winner:");
    
    if (_better_edp == 1) {
        draw_set_color(c_orange);
        draw_text(_x + 10, _cur_y + 20, "Run 1 is more efficient.");
    } else if (_better_edp == 2) {
        draw_set_color(c_aqua);
        draw_text(_x + 10, _cur_y + 20, "Run 2 is more efficient.");
    } else {
        draw_text(_x + 10, _cur_y + 20, "Equal efficiency.");
    }
}
