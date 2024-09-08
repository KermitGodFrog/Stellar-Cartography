extends Node3D

@onready var directional_light = $directional_light

func update_star_z_rot(new_z_rot: float):
	directional_light.rotation.z = new_z_rot
	pass
