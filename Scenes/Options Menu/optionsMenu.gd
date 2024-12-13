extends Control

@onready var keybind_button_group = load("res://Scenes/Options Menu/keybind_button_group.tres")
@onready var keybind_option = load("res://Scenes/Options Menu/keybind_option.tscn")
@onready var audio_slider_option = load("res://Scenes/Options Menu/audio_slider_option.tscn")
@onready var scroll = $scroll_container/scroll

var keybind_options: Array[Node] = []
var audio_slider_options: Array[Node] = []

#options to add:
#fullscreen (toggle)
#in the future: UI size options?

func initialize():
	for child in scroll.get_children():
		child.queue_free()
	keybind_options.clear()
	audio_slider_options.clear()
	
	for bus_name in ["Master", "Planetary SFX", "SFX", "Music"]:
		var new = audio_slider_option.instantiate()
		new.linked_bus_idx = AudioServer.get_bus_index(bus_name)
		scroll.add_child(new)
		new.reset_display()
		audio_slider_options.append(new)
	
	var actions: Array[StringName] = InputMap.get_actions()
	for action: StringName in actions:
		if action.begins_with("SC_"):
			var new = keybind_option.instantiate()
			new.set_button_group(keybind_button_group)
			new.linked_action = action
			scroll.add_child(new)
			new.reset_display()
			keybind_options.append(new)
	pass

func _on_back_button_pressed():
	visible = !visible
	pass

func _on_save_button_pressed():
	for option in audio_slider_options:
		AudioServer.set_bus_volume_db(option.linked_bus_idx, linear_to_db(option.last_value))
	
	for option in keybind_options:
		if option.last_input_event:
			InputMap.action_erase_events(option.linked_action)
			InputMap.action_add_event(option.linked_action, option.last_input_event)
	pass
