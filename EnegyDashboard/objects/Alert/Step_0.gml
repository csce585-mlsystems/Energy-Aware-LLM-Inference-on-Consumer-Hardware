
life_time -= 1;

if (life_time <= 0) {
    instance_destroy();
} else if (life_time <= fade_time) {
    alpha = life_time / fade_time;
}
