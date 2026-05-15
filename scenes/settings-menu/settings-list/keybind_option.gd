extends Button

signal changed()

var linked_action : StringName 
var last_input_event : InputEvent:
	set(value):
		last_input_event = value
		_on_last_input_event_changed()
		emit_signal("changed")


func reset_display() -> void:
	set_text("%s: %s" % [
		linked_action, 
		global_data.convert_events_to_readable(InputMap.action_get_events(linked_action))
		])
	pass

func update_display() -> void:
	set_text("%s: %s" % [
		linked_action, 
		global_data.convert_events_to_readable([last_input_event])
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

func _on_last_input_event_changed():
	update_display()
	pass
