extends actor3D

func _on_scope_mode_changed(new_mode: playerAPI.SCOPE_MODES) -> void:
	match new_mode:
		playerAPI.SCOPE_MODES.VIS:
			mesh_instance.set_transparency(0.0)
		playerAPI.SCOPE_MODES.RAD:
			mesh_instance.set_transparency(0.9)
	pass
