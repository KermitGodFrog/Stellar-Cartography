extends AnimatedSprite3D

var identifier: int

var velocity_position_hint: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO] #player position last frame, self position last frame
var last_distance_hint: float
var _player_position: Vector2 #set by unit_3d.gd _physics_process
var _associated_position: Vector2 #set by unit_3d.gd _physics_process

#var blueshift: bool = false

func _physics_process(delta: float) -> void:
	var current_distance_hint = _associated_position.distance_to(_player_position)
	
	var player_displacement = _player_position - velocity_position_hint[0]
	var player_velocity = player_displacement / delta
	var displacement = _associated_position - velocity_position_hint[1]
	var velocity = displacement / delta
	var limited_vel_difference = (player_velocity - velocity).limit_length()
	var difference_length = limited_vel_difference.length()
	
	if current_distance_hint > last_distance_hint: # moving away - redshift
		modulate = modulate.lerp(Color.from_hsv(1.0, difference_length / 2.5, 1.0), delta)
	elif current_distance_hint < last_distance_hint: # moving towards - blueshift
		modulate = modulate.lerp(Color.from_hsv(0.6, difference_length / 2.5, 1.0), delta)
	
	velocity_position_hint[0] = _player_position
	velocity_position_hint[1] = _associated_position
	last_distance_hint = current_distance_hint
	pass

func get_identifier():
	return identifier
func set_identifier(new_identifier: int):
	identifier = new_identifier
	pass

func initialize(_pixel_size: float):
	set_pixel_size(_pixel_size)
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
