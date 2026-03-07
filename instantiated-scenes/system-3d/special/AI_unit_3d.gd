extends actor3D

#needs to update animation in real time!

var velocity_position_hint: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO] #player position last frame, self position last frame
var last_distance_hint: float
var _player_position: Vector2 #set by unit_3d.gd _physics_process
var _associated_position: Vector2 #set by unit_3d.gd _physics_process

func _physics_process(delta: float) -> void:
	var current_distance_hint = _associated_position.distance_to(_player_position)
	
	var player_displacement = _player_position - velocity_position_hint[0]
	var player_velocity = player_displacement / delta
	var displacement = _associated_position - velocity_position_hint[1]
	var velocity = displacement / delta
	var limited_vel_difference = (player_velocity - velocity).limit_length()
	var difference_length = limited_vel_difference.length()
	
	if current_distance_hint > last_distance_hint: # moving away - redshift
		sprite.modulate = sprite.modulate.lerp(Color.from_hsv(1.0, difference_length / 2.5, 1.0), delta)
	elif current_distance_hint < last_distance_hint: # moving towards - blueshift
		sprite.modulate = sprite.modulate.lerp(Color.from_hsv(0.6, difference_length / 2.5, 1.0), delta)
	
	velocity_position_hint[0] = _player_position
	velocity_position_hint[1] = _associated_position
	last_distance_hint = current_distance_hint
	pass

func _on_scope_mode_changed(_new_mode: playerAPI.SCOPE_MODES) -> void:
	match _new_mode:
		playerAPI.SCOPE_MODES.VIS:
			hide()
		playerAPI.SCOPE_MODES.RAD:
			show()
	pass
