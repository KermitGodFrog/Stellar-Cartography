extends CanvasLayer

@onready var background_texture = $background_texture

var backgrounds: Array = []
var bg_load_thread: Thread
var bg_load_mutex = Mutex

func _ready() -> void:
	bg_load_mutex = Mutex.new()
	bg_load_thread = Thread.new()
	bg_load_thread.start(load_backgrounds)
	pass
func load_backgrounds() -> void:
	var _backgrounds: Array = []
	var paths = global_data.get_all_files("res://graphics/system-map/background", "png")
	for path in paths:
		_backgrounds.append(load(path))
	bg_load_mutex.lock()
	backgrounds = _backgrounds
	bg_load_mutex.unlock()
	pass
func _exit_tree() -> void:
	bg_load_thread.wait_to_finish()
	pass



func new_background() -> void:
	if bg_load_thread.is_alive():
		bg_load_thread.wait_to_finish()
	var new_bg = backgrounds.pick_random()
	background_texture.set_texture(new_bg)
	background_texture.flip_h = bool(global_data.get_randi(0, 1))
	background_texture.flip_v = bool(global_data.get_randi(0, 1))
	background_texture.set_modulate(Color(Color.WHITE, global_data.get_randf(0.08, 0.25)))
	pass
