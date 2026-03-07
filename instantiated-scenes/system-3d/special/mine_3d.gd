extends actor3D

var oscillation_time: float = 0.0

func _process(delta: float) -> void:
	oscillation_time += delta * 4.0
	sprite.set_transparency(sin(oscillation_time))
	pass

func _on_scope_mode_changed(new_mode: playerAPI.SCOPE_MODES) -> void:
	match new_mode:
		playerAPI.SCOPE_MODES.VIS:
			hide()
		playerAPI.SCOPE_MODES.RAD:
			show()
	pass
