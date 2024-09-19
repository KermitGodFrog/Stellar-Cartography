extends Node3D

@onready var directional_light = $directional_light
@onready var camera = $camera_offset/camera
@onready var camera_offset = $camera_offset

const CAMERA_ROTATION_MAGNITUDE = 1
var target_fov: float = 75

var current_entity : entityAPI = null
var player_position: Vector2 = Vector2.ZERO

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var viewport_size_y = get_viewport().get_visible_rect().size.y
			var viewport_size_x = get_viewport().get_visible_rect().size.x
			var mouse_pos_y = get_viewport().get_mouse_position().y
			var mouse_pos_x = get_viewport().get_mouse_position().x
			
			if mouse_pos_y > (viewport_size_y - viewport_size_y / 10):
				rotate_camera_basis(Vector3.LEFT)
			if mouse_pos_y < (viewport_size_y / 10):
				rotate_camera_basis(Vector3.RIGHT)
			if mouse_pos_x > (viewport_size_x - viewport_size_x / 10):
				rotate_camera_basis(Vector3.DOWN)
			if mouse_pos_x < (viewport_size_x / 10):
				rotate_camera_basis(Vector3.UP)
	pass

func rotate_camera_basis(dir: Vector3) -> void:
	camera.transform.basis = camera.transform.basis.rotated(dir, deg_to_rad(CAMERA_ROTATION_MAGNITUDE))
	pass



func _physics_process(delta):
	camera.fov = lerp(camera.fov, target_fov, 0.05)
	if current_entity:
		var dir = player_position.direction_to(current_entity.position)
		update_camera_offset_dir(Vector3(dir.x, 0, dir.y))
	pass








func _on_current_entity_changed(new_entity : entityAPI):
	current_entity = new_entity
	#regenerate terrain and stuff!
	pass

func _on_current_entity_cleared():
	current_entity = null
	#degererate terrain and stuff and dont allow player to view the scopes n stuff just blank screen n stuff yknow yknow
	pass




func update_star_dir(dir: Vector3) -> void:
	directional_light.transform.basis = directional_light.transform.basis.looking_at(dir)
	pass

func update_camera_offset_dir(dir: Vector3) -> void:
	camera_offset.transform.basis = camera_offset.transform.basis.looking_at(dir)
	pass


func _on_fov_slider_value_changed(value):
	target_fov = value
	pass
