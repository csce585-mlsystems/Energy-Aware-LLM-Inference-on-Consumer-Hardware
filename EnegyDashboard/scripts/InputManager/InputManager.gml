/// @function request_latest_data(_backend)
/// @description Requests the latest data for the specified backend.
function request_latest_data(_backend) {
    // Reset Timer & Request
    reset_inference_timer();
    
    // We pass a placeholder prompt because the server ignores it in file-mode
    request_inference("FETCH_LATEST", _backend);
    
    show_debug_message("📥 Requesting latest " + string_upper(_backend) + " data...");
}