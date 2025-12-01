draw_set_color(c_white);

// Debug info
//draw_text(10, 10, "Request ID: " + string(global.http_request_id));
//draw_text(10, 30, "Has Data: " + string(!is_undefined(global.energy_data)));

// Graph
// Graph / Content Area
if (global.current_tab == "ranking") {
    draw_ranking_tab();
} 
else {
    // Dispatch to GraphRenderer for all other tabs (live_trace, energy_vs_latency, etc.)
    // The renderer handles data checks internally.
    draw_energy_graph(50, 100, 800, 400);
}

// Show loading animation while waiting
if (global.http_request_id != -1) {
    var _dots = string_repeat(".", floor((current_time / 500) % 4));
    draw_text(50, 550, "Running Inference" + _dots);
    draw_text(50, 570, "Watch the terminal for live logs!");
}

draw_inference_progress();