extends Label
#why did i need a whole new script for this? should just make a bunch of versatile blinking, fading, etc scripts that can be used anywhere

func _process(delta):
	self_modulate = self_modulate.lerp(Color.WHITE, 2.5 * delta)
	pass

func blink(_color: Color):
	set_self_modulate(_color)
	pass
