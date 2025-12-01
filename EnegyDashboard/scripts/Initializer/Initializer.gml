global.current_tab = "live_trace"; // Track which tab is active
global.p2_data_loaded = false;     // Flag to load CSV data once
global.p2_data = {};               // Store parsed P2 analysis data
global.all_runs = [];              // Store ALL runs for analysis graphs
global.http_request_history_id = -1; // Track history request
global.history_loaded = false;       // Flag to prevent double loading if needed
global.compare_run_1 = undefined;    // First run selected for comparison
global.compare_run_2 = undefined;    // Second run selected for comparison