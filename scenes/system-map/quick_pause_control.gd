extends Control

var _pause_mode: game_data.PAUSE_MODES = game_data.PAUSE_MODES.NONE
signal _setPauseMode(_new_mode: game_data.PAUSE_MODES) #sent to system_map.gd!

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("SC_QUICK_PAUSE"):
		if _pause_mode == game_data.PAUSE_MODES.QUICK_PAUSE:
			emit_signal("_setPauseMode", game_data.PAUSE_MODES.NONE)
	pass
