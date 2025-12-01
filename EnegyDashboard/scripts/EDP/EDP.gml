function calculate_edp(_run) {
    if (is_undefined(_run)) return 0;
    
    var _energy = 0;
    var _latency_ms = 0;
    
    if (variable_struct_exists(_run, "energy_joules")) {
        _energy = _run.energy_joules;
    }
    
    if (variable_struct_exists(_run, "latency_ms")) {
        _latency_ms = _run.latency_ms;
    }
    
    var _latency_s = _latency_ms / 1000.0;
    
    return _energy * _latency_s;
}
