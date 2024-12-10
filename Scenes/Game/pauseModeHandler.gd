extends Node

signal pauseModeChanged(new_mode: game_data.PAUSE_MODES)

var pause_mode: game_data.PAUSE_MODES = game_data.PAUSE_MODES.NONE:
	set(value):
		pause_mode = value
		emit_signal("pauseModeChanged", value)
var pause_queue: Array[game_data.PAUSE_MODES] = []

func _ready():
	pauseModeChanged.connect(_on_pause_mode_changed)
	pass

func _process(delta):
	#print("PAUSE_MODE: ", pause_mode)
	#print("PAUSE_QUEUE: ", pause_queue)
	#print(get_tree().paused)
	if pause_mode == game_data.PAUSE_MODES.NONE:
		var new_mode = pause_queue.pop_front()
		if new_mode != null:
			pause_mode = new_mode
	pass

func _on_queue_pause_mode(new_mode: game_data.PAUSE_MODES) -> void:
	var p = pause_queue.duplicate()
	var b = p.pop_back()
	if b != new_mode:
		pause_queue.append(new_mode)
	pass

func _on_set_pause_mode(new_mode: game_data.PAUSE_MODES) -> void:
	pause_mode = new_mode
	pass

func _on_pause_mode_changed(new_mode: game_data.PAUSE_MODES) -> void:
	match new_mode:
		game_data.PAUSE_MODES.NONE:
			get_tree().paused = false
		_:
			get_tree().paused = true
	pass
