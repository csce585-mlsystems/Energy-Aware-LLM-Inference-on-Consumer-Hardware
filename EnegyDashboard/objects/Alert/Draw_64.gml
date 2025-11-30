var old_font  = draw_get_font();
var old_halign = draw_get_halign();
var old_valign = draw_get_valign();

draw_set_font(Small);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);

var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

var box_w  = 260;
var box_h  = 32;
var margin = 8;
var gap    = 4;

// 1) Figure out my index by creation order
//    (how many alerts are older than me?)
index = 0;
with (Alert)
{
    if (id < other.id) { // "id" here is this alert in the loop, "other" is the one drawing
        other.index++;
    }
}

// total alerts
var count = instance_number(Alert);

// 2) Newest at slot 0, older get bigger slot
var slot = count - 1 - index;

// If we want only last N alerts, hide the rest
if (slot >= max_alerts) {
    exit; // don’t draw this one
}

// 3) Position from the TOP-LEFT
var x1 = margin;
var y1 = margin + (box_h + gap) * slot;
var x2 = x1 + box_w;
var y2 = y1 + box_h;

// 4) Draw box
draw_set_alpha(alpha);
draw_set_color(bg_col);
draw_rectangle(x1, y1, x2, y2, false);

// Accent bar
draw_set_color(c_red);
draw_rectangle(x1, y1, x1 + 4, y2, false);

// Text
draw_set_color(text_col);
draw_text(x1 + 10, y1 + 8, msg);

draw_set_alpha(1);
draw_set_font(old_font);
draw_set_halign(old_halign);
draw_set_valign(old_valign);