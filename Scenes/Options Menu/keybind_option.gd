extends Button

func _input(event):
	if event is InputEventKey:
		if get_button_group().get_pressed_button() == self:
			set_text(OS.get_keycode_string(event.keycode))
	pass
