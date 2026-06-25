extends Control

signal exiting()

@onready var keybind_button_group = preload("uid://ds237xjai4y42")
@onready var keybind_option = preload("uid://cbaykf0eovygh")
@onready var audio_slider_option = preload("uid://b564nt73u2b3j")

@onready var settings_list = $panel/margin/panel_scroll/list_container/settings_list
@onready var confirmation_dialog = $confirmation_dialog

var keybind_options: Array[Node] = []
var audio_slider_options: Array[Node] = []

var exit_type: global_data.SETTINGS_EXIT_TYPES = global_data.SETTINGS_EXIT_TYPES.INSTANCE
var exit_path: String = String() #only relevant for exit type SCENE

var unsaved_changes: bool = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("SC_PAUSE"):
		_on_back_button_pressed()
	pass

func _ready() -> void:
	#for child in settings_list.get_children():
	#	child.queue_free()
	#keybind_options.clear()
	#audio_slider_options.clear()
	
	for bus_name in game_data.SETTINGS_RELEVANT_AUDIO_BUSES:
		var new = audio_slider_option.instantiate()
		new.linked_bus_idx = AudioServer.get_bus_index(bus_name)
		settings_list.add_child(new)
		new.reset_display()
		new.connect("changed", _on_option_changed)
		audio_slider_options.append(new)
	
	for action in global_data.get_relevant_input_actions():
		var new = keybind_option.instantiate()
		new.set_button_group(keybind_button_group)
		new.linked_action = action
		settings_list.add_child(new)
		new.reset_display()
		new.connect("changed", _on_option_changed)
		keybind_options.append(new)
	pass

func _on_back_button_pressed():
	if unsaved_changes:
		confirmation_dialog.popup()
	else:
		exit()
	pass

func exit() -> void:
	emit_signal("exiting")
	match exit_type:
		global_data.SETTINGS_EXIT_TYPES.INSTANCE:
			queue_free()
		global_data.SETTINGS_EXIT_TYPES.SCENE:
			global_data.change_scene.emit(exit_path)
	pass

func _on_save_button_pressed():
	unsaved_changes = false
	
	for option in audio_slider_options:
		AudioServer.set_bus_volume_db(option.linked_bus_idx, linear_to_db(option.last_value))
	
	for option in keybind_options:
		if option.last_input_event:
			InputMap.action_erase_events(option.linked_action)
			InputMap.action_add_event(option.linked_action, option.last_input_event)
	
	var helper = settingsHelper.new()
	
	for bus_name in game_data.SETTINGS_RELEVANT_AUDIO_BUSES:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		helper.saved_bus_volumes.append(AudioServer.get_bus_volume_db(bus_idx))
	
	var relevant_actions = global_data.get_relevant_input_actions() # all starting with SC_
	for action in relevant_actions:
		var events = InputMap.action_get_events(action)
		if events: helper.saved_events.append(events.front()) #support for only ONE keybind per action
		else: helper.saved_events.append(null)
	
	game_data.saveSettings(helper)
	pass

func _on_reset_button_pressed():
	for option in audio_slider_options:
		option.last_value = db_to_linear(0.0)
		option.slider.value = option.last_value # moving the slider manually
	
	var default_events = game_data.DEFAULT_SETTINGS_RELEVANT_ACTION_EVENTS
	for i in keybind_options.size():
		var option = keybind_options[i]
		option.last_input_event = default_events[i]
	pass




func _on_option_changed() -> void:
	unsaved_changes = true
	pass

func _on_confirmation_dialog_confirmed() -> void:
	exit()
	pass
