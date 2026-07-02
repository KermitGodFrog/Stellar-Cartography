extends Control

signal exiting()

@onready var keybind_button_group = preload("uid://ds237xjai4y42")
@onready var keybind_option = preload("uid://cbaykf0eovygh")
@onready var audio_slider_option = preload("uid://b564nt73u2b3j")

@onready var settings_list = $panel/margin/panel_scroll/list_description_split/list_container/settings_list
@onready var confirmation_dialog = $confirmation_dialog
@onready var description = $panel/margin/panel_scroll/list_description_split/description
@onready var panel = $panel

@onready var options: Array[Node] = []
@onready var keybind_options: Array[Node] = []
@onready var audio_slider_options: Array[Node] = []
@onready var dropdown_options: Array[Node] = [$panel/margin/panel_scroll/list_description_split/list_container/settings_list/window_mode, $panel/margin/panel_scroll/list_description_split/list_container/settings_list/fps_limit]

var exit_type: global_data.SETTINGS_EXIT_TYPES = global_data.SETTINGS_EXIT_TYPES.INSTANCE
var exit_path: String = String() #only relevant for exit type SCENE

var unsaved_changes: bool = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("SC_PAUSE"):
		_on_back_button_pressed()
	pass

func _ready() -> void:
	panel.connect("gui_input", _on_irrelevant_gui_input)
	settings_list.connect("gui_input", _on_irrelevant_gui_input)
	description.connect("gui_input", _on_irrelevant_gui_input)
	
	for bus_name in game_data.SETTINGS_RELEVANT_AUDIO_BUSES:
		var new = audio_slider_option.instantiate()
		new.linked_bus_idx = AudioServer.get_bus_index(bus_name)
		settings_list.add_child(new)
		audio_slider_options.append(new)
		options.append(new)
	
	for action in global_data.get_relevant_input_actions():
		var new = keybind_option.instantiate()
		new.group = keybind_button_group
		new.linked_action = action
		settings_list.add_child(new)
		keybind_options.append(new)
		options.append(new)
	
	for options_array in [keybind_options, audio_slider_options, dropdown_options]:
		options.append_array(options_array)
	
	for o in options:
		o.reset_display()
		o.connect("changed", _on_option_changed)
		o.connect("hovered", _on_option_hovered)
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

func _on_save_button_pressed(): #updates AudioServer, InputMap, DisplayServer, Engine, etc with the new values and then takes those values from those updated locations and packs it into settingsHelper before saving it
	unsaved_changes = false
	
	for option in audio_slider_options:
		AudioServer.set_bus_volume_db(option.linked_bus_idx, linear_to_db(option.last_value))
	
	for option in keybind_options:
		if option.last_input_event:
			InputMap.action_erase_events(option.linked_action)
			InputMap.action_add_event(option.linked_action, option.last_input_event)
	
	for option in dropdown_options:
		match option.get_wID():
			"WINDOW_MODE":
				DisplayServer.window_set_mode(option.dropdown.get_selected_id())
			"FPS_LIMIT":
				match option.dropdown.get_selected_id():
					0:
						Engine.set_max_fps(0)
					_:
						Engine.set_max_fps(option.dropdown.get_item_text(option.dropdown.get_selected()).to_int())
	
	var helper = settingsHelper.new()
	
	for bus_name in game_data.SETTINGS_RELEVANT_AUDIO_BUSES:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		helper.saved_bus_volumes.append(AudioServer.get_bus_volume_db(bus_idx))
	
	var relevant_actions = global_data.get_relevant_input_actions() # all starting with SC_
	for action in relevant_actions:
		var events = InputMap.action_get_events(action)
		if events: helper.saved_events.append(events.front()) #support for only ONE keybind per action
		else: helper.saved_events.append(null)
	
	helper.window_mode = DisplayServer.window_get_mode()
	helper.fps_limit = Engine.get_max_fps()
	
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

func _on_option_hovered(wID: String) -> void:
	var text: String = String()
	match wID:
		_:
			text = "NO DESCRIPTION YET"
	
	description.clear()
	description.append_text(text)
	pass




func _on_confirmation_dialog_confirmed() -> void:
	exit()
	pass

func _on_irrelevant_gui_input(event) -> void:
	if event is InputEventMouseButton:
		for option in keybind_options:
			option.button.button_pressed = false
	pass
