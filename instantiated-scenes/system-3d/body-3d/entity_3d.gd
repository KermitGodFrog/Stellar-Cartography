extends Sprite3D

var identifier: int

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
