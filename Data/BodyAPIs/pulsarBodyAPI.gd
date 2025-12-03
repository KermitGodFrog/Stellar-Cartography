extends circularBodyAPI
class_name pulsarBodyAPI

@export_storage var beam_rotation: float
@export var beam_angle_change: float 
@export var beam_width: float #IN SOLAR RADII, NOT ANGLE !!!

func initialize() -> void:
	beam_rotation = deg_to_rad(global_data.get_randf(0,360))
	pass

func advance(delta) -> void:
	beam_rotation += beam_angle_change * delta
	pass
