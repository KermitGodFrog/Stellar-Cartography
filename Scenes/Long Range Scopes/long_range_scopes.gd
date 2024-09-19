extends Node3D

@onready var directional_light = $directional_light
@onready var camera = $camera_offset/camera
@onready var camera_offset = $camera_offset























func update_star_dir(dir: Vector3) -> void:
	directional_light.transform.basis = directional_light.transform.basis.looking_at(dir)
	pass

func update_camera_offset_dir(dir: Vector3) -> void:
	camera_offset.transform.basis = camera_offset.transform.basis.looking_at(dir)
	pass
