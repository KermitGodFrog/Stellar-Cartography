extends "res://scenes/settings-menu/settings-list/option.gd"

@onready var button = $button

var linked_action : StringName 
var last_input_event : InputEvent:
	set(value):
		last_input_event = value
		_on_last_input_event_changed()
		emit_signal("changed")
var group: ButtonGroup

func _ready() -> void:
	wID = "KEYBIND_LINKED_ACTION_%s" % linked_action
	button.button_group = group
	super()
	pass

func reset_display() -> void:
	button.set_text("%s: %s" % [
		linked_action, 
		global_data.convert_events_to_readable(InputMap.action_get_events(linked_action))
		])
	pass

func update_display() -> void:
	button.set_text("%s: %s" % [
		linked_action, 
		global_data.convert_events_to_readable([last_input_event])
		])
	pass

func _on_button_gui_input(event: InputEvent) -> void:
	if button.get_button_group().get_pressed_button() == button:
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


func _on_button_mouse_entered() -> void:
	emit_signal("hovered", get_wID())
	pass
