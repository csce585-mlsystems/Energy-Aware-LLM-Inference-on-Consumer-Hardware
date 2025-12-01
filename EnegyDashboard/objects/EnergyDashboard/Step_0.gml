// Auto-reset progress bar after completion
if (variable_global_exists("server_progress") && global.server_progress >= 1.0) {
    progress_reset_timer++;
    if (progress_reset_timer > 120) { // 2 seconds at 60fps
        global.server_progress = 0.0;
        global.server_step_name = "Ready";
        progress_reset_timer = 0;
    }
} else {
    progress_reset_timer = 0;
}

// Polling is handled by obj_progress_poller now, so we can remove the old code here.