extends "res://scenes/settings-menu/settings-list/option.gd"

@onready var button = $button

var linked_action : StringName 
var last_input_event : InputEvent:
	set(value):
		last_input_event = value
		_on_last_input_event_changed()
		emit_signal("changed", get_wID())
var group: ButtonGroup

func _ready() -> void:
	wID = "KEYBIND_LINKED_ACTION_%s" % linked_action
	button.button_group = group
	super()
	pass

func reset_display_to_applied() -> void: #reset to current applied settings
	var events = InputMap.action_get_events(linked_action)
	if events.size() > 0:
		last_input_event = events.front()
	else:
		last_input_event = null
	button.set_text("%s: %s" % [
		linked_action.right(-3), #-3 to remove 'SC_'
		global_data.convert_events_to_readable(events)
		])
	pass

func reset_display_to_default() -> void: #reset to default settings
	#for keybind options, this is handled by settings_menu as it cannot be done locally !
	pass

func update_display() -> void:
	button.set_text("%s: %s" % [
		linked_action.right(-3), #-3 to remove 'SC_'
		global_data.convert_events_to_readable([last_input_event])
		])
	pass




func _on_button_gui_input(event: InputEvent) -> void:
	if button.get_button_group().get_pressed_button() == button:
		if event is InputEventKey \
		or event is InputEventJoypadButton \
		or event is InputEventMouseButton:
			last_input_event = event
	pass

func _on_last_input_event_changed():
	update_display()
	pass

func _on_button_mouse_entered() -> void:
	emit_signal("hovered", get_wID())
	pass
