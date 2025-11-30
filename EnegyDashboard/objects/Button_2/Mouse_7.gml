sprite_index = button_2;

// Switch tab based on the button's assigned type
if type == "live_trace"{
    global.current_tab = type;
    output("Switched to tab: " + type);
}

else if type == "draw_energy_vs_latency"{
    global.current_tab = type;
    output("Switched to tab: " + type);
}

else if type == "ablation_studies"{
    global.current_tab = type;
    output("Switched to tab: " + type);
}

else if type == "metrics_comparison"{
    global.current_tab = type;
    output("Switched to tab: " + type);
}