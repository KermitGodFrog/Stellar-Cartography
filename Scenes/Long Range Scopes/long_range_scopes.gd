extends Node3D

@onready var directional_light = $directional_light
@onready var camera = $camera_offset/camera
@onready var camera_offset = $camera_offset

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var viewport_size_y = get_viewport().get_visible_rect().size.y
			var viewport_size_x = get_viewport().get_visible_rect().size.x
			var mouse_pos_y = get_viewport().get_mouse_position().y
			var mouse_pos_x = get_viewport().get_mouse_position().x
			
			if mouse_pos_y > (viewport_size_y - viewport_size_y / 10):
				camera.transform.basis = camera.transform.basis.rotated(Vector3.LEFT, deg_to_rad(1))
			if mouse_pos_y < (viewport_size_y / 10):
				camera.transform.basis = camera.transform.basis.rotated(Vector3.RIGHT, deg_to_rad(1))
			
			if mouse_pos_x > (viewport_size_x - viewport_size_x / 10):
				camera.transform.basis = camera.transform.basis.rotated(Vector3.DOWN, deg_to_rad(1))
			if mouse_pos_x < (viewport_size_x / 10):
				camera.transform.basis = camera.transform.basis.rotated(Vector3.UP, deg_to_rad(1))
	pass




func _physics_process(delta):
	pass
















func update_star_dir(dir: Vector3) -> void:
	directional_light.transform.basis = directional_light.transform.basis.looking_at(dir)
	pass

func update_camera_offset_dir(dir: Vector3) -> void:
	camera_offset.transform.basis = camera_offset.transform.basis.looking_at(dir)
	pass
