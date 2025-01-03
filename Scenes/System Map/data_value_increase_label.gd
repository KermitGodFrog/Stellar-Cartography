extends Label

const max_hide_time: int = 250
var hide_time: int = 0:
	set(value):
		hide_time = maxi(0, value)

@export var hide_curve: Curve

func blink() -> void:
	hide_time = max_hide_time
	pass

func _physics_process(delta):
	hide_time -= delta
	set_self_modulate(Color(1,1,1,hide_curve.sample(remap(hide_time, 0, max_hide_time, 0, 1))))
	pass
