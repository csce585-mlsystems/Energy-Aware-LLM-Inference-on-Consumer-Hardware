// Toggle fullscreen
window_set_fullscreen(!window_get_fullscreen());

global.is_fullscreen = window_get_fullscreen();

if (global.is_fullscreen){
	output("Entered Fullscreen")
}
else{
	output("Exited Fullscreen")
}
