extends TextureRect

func _process(delta: float) -> void:
	texture.noise.offset.y += delta
	pass
