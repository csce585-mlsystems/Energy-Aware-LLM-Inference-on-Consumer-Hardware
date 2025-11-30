persistent = true;
// ===== config =====
max_alerts     = 100;   // max visible alerts at once
life_time_sec  = 3;   // total lifetime
fade_time_sec  = 0.5; // last 0.5s fade out

// ===== manage max stack =====
// how many alerts existed BEFORE this one
var prev_count = instance_number(Alert) - 1;

// if we already had max_alerts, kill the oldest one
if (prev_count >= max_alerts) {
    var oldest = instance_find(Alert, 0);
    if (oldest != id) {
        with (oldest) instance_destroy();
        prev_count -= 1;
    }
}

// our order in the stack (0 = top, 1 = next, ...)
order = prev_count;

// ===== basic data =====
msg = "Default alert";  // override when creating the instance

life_time = life_time_sec * room_speed;
fade_time = fade_time_sec * room_speed;

alpha = 1;

bg_col   = make_color_rgb(20, 20, 20);
text_col = c_white;
