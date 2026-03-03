extends MeshInstance3D

var identifier: int

var oscillation_time: float = 0.0

func _process(delta: float) -> void:
	oscillation_time += delta * 4.0
	set_transparency(sin(oscillation_time))
	pass

func get_identifier():
	return identifier
func set_identifier(new_identifier: int):
	identifier = new_identifier
	pass

func initialize(scalar: float) -> void:
	mesh.set_size(Vector2(scalar, scalar))
	pass

func updatePosition(pos: Vector3):
	position = pos
	pass

func _on_scope_mode_changed(new_mode: playerAPI.SCOPE_MODES) -> void:
	match new_mode:
		playerAPI.SCOPE_MODES.VIS:
			hide()
		playerAPI.SCOPE_MODES.RAD:
			show()
	pass
