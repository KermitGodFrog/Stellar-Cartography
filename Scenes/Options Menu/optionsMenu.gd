extends Control

@onready var keybind_button_group = load("res://Scenes/Options Menu/keybind_button_group.tres")
@onready var keybind_option = load("res://Scenes/Options Menu/keybind_option.tscn")
@onready var scroll = $scroll_container/scroll

var options: Array[Node] = []

#options to add:
#fullscreen (toggle)
#in the future: UI size options?

func initialize():
	for child in scroll.get_children():
		child.queue_free()
		options.clear()
	
	var actions: Array[StringName] = InputMap.get_actions()
	for action: StringName in actions:
		if action.begins_with("SC_"):
			var new = keybind_option.instantiate()
			new.set_button_group(keybind_button_group)
			new.linked_action = action
			new.reset_display()
			scroll.add_child(new)
			options.append(new)
	pass

func _on_back_button_pressed():
	visible = !visible
	pass

func _on_save_button_pressed():
	for option in options:
		if option.last_input_event:
			InputMap.action_erase_events(option.linked_action)
			InputMap.action_add_event(option.linked_action, option.last_input_event)
	pass
