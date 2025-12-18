extends Button

var time: float = 0.0

var oscillate: bool = false


func _process(delta: float) -> void:
	time += delta
	set("self_modulate", self_modulate.lerp(Color.WHITE, 2.5 * delta))
	if oscillate:
		set("self_modulate", Color(sin(time * 5.0), 1.0, sin(time * 5.0)))
	pass

#taken from disclaimer_label station_UI - gotta sort out all these duplicates at some point
func blink(_color: Color):
	set_self_modulate(_color)
	pass
