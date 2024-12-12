extends Button

var action : StringName 
@export var input_event : InputEvent




func _input(event):
	if event is InputEventKey:
		if get_button_group().get_pressed_button() == self:
			input_event = event
			set_text(OS.get_keycode_string(event.keycode))
	if event is InputEventJoypadButton:
		if get_button_group().get_pressed_button() == self:
			input_event = event
			set_text(str(event.button_index))
	#if event is InputEventMouseButton:
		#if get_button_group().get_pressed_button() == self:
			#input_event = event
			#set_text(str(event.button_index))
	print(input_event)
	pass
