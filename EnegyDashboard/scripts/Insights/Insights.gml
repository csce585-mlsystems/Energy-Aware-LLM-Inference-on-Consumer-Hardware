/// @function get_live_trace_insight(_run)
/// @description Generates insight text for the Live Trace view
function get_live_trace_insight(_run) {
    if (is_undefined(_run)) return "Press 'Run CPU' or 'Run GPU' to start.";
    
    // 1. Calculate Peak Power
    var _peak_power = 0;
    var _trace = _run.power_trace;
    for (var i = 0; i < array_length(_trace); i++) {
        if (_trace[i] > _peak_power) _peak_power = _trace[i];
    }
    
    // 2. Calculate Avg Power
    var _duration_sec = _run.latency_ms / 1000;
    var _avg_power = (_duration_sec > 0) ? (_run.energy_joules / _duration_sec) : 0;
    
    var _text = "";
    
    // 3. Generate Insight
    if (_run.backend == "gpu") {
        _text = "Strategy: RACE TO SLEEP\n";
        _text += "• Peak: " + string_format(_peak_power, 1, 0) + " W\n";
        _text += "• Avg: " + string_format(_avg_power, 1, 0) + " W\n\n";
        _text += "Insight: High power draw is offset by fast execution, resulting in lower total energy.";
    } else {
        _text = "Strategy: LOW & SLOW\n";
        _text += "• Peak: " + string_format(_peak_power, 1, 0) + " W\n";
        _text += "• Avg: " + string_format(_avg_power, 1, 0) + " W\n\n";
        _text += "Insight: Lower wattage, but long duration increases total energy cost.";
    }
    
    return _text;
}

/// @function get_metrics_insight(_cpu_count, _gpu_count, _speedup, _savings)
/// @description Generates insight text for the Metrics Comparison view
function get_metrics_insight(_cpu_count, _gpu_count, _speedup, _savings) {
    var _msg = "";
    
    if (_cpu_count > 0 && _gpu_count > 0) {
        _msg = "Aggregated stats from all runs:\n\n";
        _msg += "• Speedup: " + string_format(_speedup, 1, 1) + "x\n";
        _msg += "• Energy Saved: " + string_format(_savings, 1, 0) + "%\n\n";
        _msg += "Conclusion: GPU provides significant latency reduction while also saving total energy.";
    } else if (_cpu_count > 0) {
        _msg = "Run GPU to compare.";
    } else if (_gpu_count > 0) {
        _msg = "Run CPU to compare.";
    } else {
        _msg = "Run inference to see comparison.";
    }
    
    return _msg;
}

/// @function get_ablation_insight(_mode)
/// @description Generates insight text for the Ablation Studies view
function get_ablation_insight(_mode) {
    var _msg = "";
    
    if (_mode == 0) { // GPU Layers
        _msg = "STUDY: GPU Layer Offloading\n\n";
        _msg += "• 0 Layers: Slowest (CPU-bound)\n";
        _msg += "• 11 Layers: Best Efficiency (Lowest EDP)\n";
        _msg += "• 22 Layers: Fastest (Lowest Latency)\n\n";
        _msg += "Insight: Offloading 11 layers hits the sweet spot between speed and power.";
    } else if (_mode == 1) { // CPU Threads
        _msg = "STUDY: CPU Thread Scaling\n\n";
        _msg += "• 1 Thread: Baseline\n";
        _msg += "• 4 Threads: ~40% Faster\n";
        _msg += "• 8 Threads: Diminishing returns\n\n";
        _msg += "Insight: Performance is memory-bound. Adding more threads beyond 4 yields minimal gains.";
    } else { // Batch Size
        _msg = "STUDY: Batch Size Scaling\n\n";
        _msg += "• 128-1024 Batch Size\n";
        _msg += "• Impact: Minimal (<15%)\n\n";
        _msg += "Insight: For single-prompt inference, batch size has little effect on latency.";
    }
    
    return _msg;
}
