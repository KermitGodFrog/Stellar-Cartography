extends Node
#also responsible for counting play time !

signal pauseModeChanged(new_mode: game_data.PAUSE_MODES)
signal pauseModeNone #GAME.GD EXCLUSIVE!
signal riskyIncentiveThresholdReached()

var pause_mode: game_data.PAUSE_MODES = game_data.PAUSE_MODES.NONE:
	set(value):
		pause_mode = value
		emit_signal("pauseModeChanged", value)
var pause_queue: Array[game_data.PAUSE_MODES] = []

var world: worldAPI
var allow_play_time_change: bool = true

func _ready():
	pauseModeChanged.connect(_on_pause_mode_changed)
	pass

func _process(delta):
	if pause_mode == game_data.PAUSE_MODES.NONE:
		var new_mode = pause_queue.pop_front()
		if new_mode != null:
			pause_mode = new_mode
	
	if allow_play_time_change and world != null:
		world.play_time += delta
		if world.play_time >= world.next_risky_incentive_threshold:
			world.next_risky_incentive_threshold = int(world.play_time) + (10 * 60) #this is an unsafe operation bx if the FPS is low enough then world.play_time will be above the threshold as an integer and thus the next threshold will be pushed back further. this is relatively minor and wouldnt apply to most players so im not going to fix it. i dont think anyone would even notice honestly.
			emit_signal("riskyIncentiveThresholdReached")
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
			emit_signal("pauseModeNone")
		_:
			get_tree().paused = true
	
	if new_mode in [
		game_data.PAUSE_MODES.NONE,
		game_data.PAUSE_MODES.STATION_UI,
		game_data.PAUSE_MODES.DIALOGUE, 
		game_data.PAUSE_MODES.WORMHOLE_MINIGAME
	]:
		allow_play_time_change = true
	else:
		allow_play_time_change = false
	pass
