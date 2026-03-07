extends MeshInstance3D

func _on_scope_mode_changed(new_mode: playerAPI.SCOPE_MODES) -> void:
	match new_mode:
		playerAPI.SCOPE_MODES.VIS:
			set_transparency(0.0)
		playerAPI.SCOPE_MODES.RAD:
			set_transparency(0.9)
	pass
