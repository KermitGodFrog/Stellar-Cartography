extends Button

var linked_action : StringName 
var last_input_event : InputEvent:
	set(value):
		_on_last_input_event_changed(value)


func reset_display() -> void:
	set_text("%s: %s" % [
		linked_action, 
		convert_events_to_readable(InputMap.action_get_events(linked_action))
		])
	pass

func update_display() -> void:
	set_text("%s: %s" % [
		linked_action, 
		convert_events_to_readable([last_input_event])
		])
	pass

func _gui_input(event):
	if get_button_group().get_pressed_button() == self:
		if event is InputEventKey:
			last_input_event = event
		if event is InputEventJoypadButton:
			last_input_event = event
		if event is InputEventMouseButton:
			last_input_event = event
	pass

func convert_events_to_readable(input_array: Array[InputEvent]) -> String:
	var s: String = ""
	for event in input_array:
		if event is InputEventKey:
			if event.physical_keycode:
				var keycode = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
				s += "%s " % OS.get_keycode_string(keycode)
			else:
				s += "%s " % OS.get_keycode_string(event.keycode)
		if event is InputEventJoypadButton:
			s += "JOY_%s " % event.button_index
		if event is InputEventMouseButton:
			s += "MOUSE_%s " % event.button_index
	return s

func _on_last_input_event_changed(new_input_event: InputEvent):
	last_input_event = new_input_event
	update_display()
	pass

