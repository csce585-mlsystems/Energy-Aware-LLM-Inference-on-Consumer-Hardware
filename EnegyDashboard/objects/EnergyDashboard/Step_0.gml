if (global.http_request_id != -1 && (current_time % 100 < 20)) {
    http_get("http://127.0.0.1:5000/status");
}