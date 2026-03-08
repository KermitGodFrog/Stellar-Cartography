extends actor3D

var oscillation_time: float = 0.0

func _process(delta: float) -> void:
	oscillation_time += delta * 4.0
	sprite.set_transparency(sin(oscillation_time))
	pass
