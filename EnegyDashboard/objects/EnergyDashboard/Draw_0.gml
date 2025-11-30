draw_set_color(c_white);

// Debug info
draw_text(10, 10, "Request ID: " + string(global.http_request_id));
draw_text(10, 30, "Has Data: " + string(!is_undefined(global.energy_data)));

// Graph
if (!is_undefined(global.energy_data)) {
    draw_energy_graph(50, 100, 800, 400);
} else {
    draw_text(50, 100, "No data yet. Press Space.");
}

// Show loading animation while waiting
if (global.http_request_id != -1) {
    var _dots = string_repeat(".", floor((current_time / 500) % 4));
    draw_text(50, 550, "Running Inference" + _dots);
    draw_text(50, 570, "Watch the terminal for live logs!");
}

draw_inference_progress();