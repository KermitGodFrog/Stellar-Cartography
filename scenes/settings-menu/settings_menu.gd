extends Control

signal exiting()

@onready var keybind_button_group = preload("uid://ds237xjai4y42")
@onready var keybind_option_scene = preload("uid://cbaykf0eovygh")
@onready var audio_slider_option_scene = preload("uid://b564nt73u2b3j")

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

func _ready() -> void:
	panel.connect("gui_input", _on_irrelevant_gui_input)
	settings_list.connect("gui_input", _on_irrelevant_gui_input)
	description.connect("gui_input", _on_irrelevant_gui_input)
	create_settings_list()
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("SC_PAUSE"):
		_on_back_button_pressed()
	pass

func _on_back_button_pressed():
	if unsaved_changes:
		confirmation_dialog.popup()
	else:
		exit()
	pass

func _on_save_button_pressed():
	unsaved_changes = false
	save_then_apply_settings_list()
	pass

func _on_reset_to_defaults_button_pressed():
	reset_settings_list_to_defaults()
	pass

func _on_confirmation_dialog_confirmed() -> void:
	exit()
	pass

func _on_option_changed(_wID: String) -> void:
	unsaved_changes = true
	pass

func _on_option_hovered(wID: String) -> void:
	var text: String = "NO DESCRIPTION YET"
	match wID:
		"KEYBIND_SC_PAUSE":
			text = "Pauses or unpauses the game and also exits certain pause menus."
		"KEYBIND_SC_SYSTEM_MAP_ZOOM_IN":
			text = "Zooms the SYSTEM MAP camera in."
		"KEYBIND_SC_SYSTEM_MAP_ZOOM_OUT":
			text = "Zooms the SYSTEM MAP camera out."
		"KEYBIND_SC_PAN":
			text = "While held, the SYSTEM MAP camera moves towards the mouse pointer."
		"KEYBIND_SC_SYSTEM_MAP_UP":
			text = "Moves the SYSTEM MAP camera up."
		"KEYBIND_SC_SYSTEM_MAP_DOWN":
			text = "Moves the SYSTEM MAP camera down."
		"KEYBIND_SC_SYSTEM_MAP_LEFT":
			text = "Moves the SYSTEM MAP camera left."
		"KEYBIND_SC_SYSTEM_MAP_RIGHT":
			text = "Moves the SYSTEM MAP camera right."
		"KEYBIND_SC_BOOST":
			text = "When pressed, the player switches between boosting and normal travel.\n\nBoosting greatly increases speed but also extends the 'SCANNER PROFILE'."
		"KEYBIND_SC_INTERACT1_LEFT_MOUSE":
			text = "Aims the player's scopes towards the mouse pointer when used on the SYSTEM MAP."
		"KEYBIND_SC_INTERACT2_RIGHT_MOUSE":
			text = "Sets the player's target position to the mouse pointer when used on the SYSTEM MAP."
		"KEYBIND_SC_INTERACT3_TAKE_PHOTO":
			text = "When pressed within the bounds of the Long Range Scopes module, a photo is taken."
		"KEYBIND_SC_INTERACT4_USE_RANGEFINDER":
			text = "When pressed within the bounds of the Long Range Scopes module, the rangefinder is shown."
		"KEYBIND_SC_DEBUG_OPEN_DEBUG_MENU":
			text = "Opens the debug menu which contains cheats used to develop the game.\n\nMany of the cheats will crash the game if used incorrectly - remember to save!"
		"KEYBIND_SC_OPEN_HELP_OVERLAY":
			text = "Shows the help overlay which displays the name of each UI element."
		"KEYBIND_SC_LOAD_CONFIRMATION":
			text = "When loading is done, exits the loading screen."
		"KEYBIND_SC_SCOPE_SWITCH":
			text = "Switches scopes between the 'RAD' and 'VIS' modes."
		"KEYBIND_SC_QUICK_PAUSE":
			text = "Quick pauses or unpauses the game.\n\nWhile quick paused, the SYSTEM MAP is visible and info popups can still be interacted with."
	
	description.clear()
	description.append_text(text)
	pass

func _on_irrelevant_gui_input(event) -> void:
	if event is InputEventMouseButton:
		for option in keybind_options:
			option.button.button_pressed = false
	pass

func exit() -> void:
	emit_signal("exiting")
	match exit_type:
		global_data.SETTINGS_EXIT_TYPES.INSTANCE:
			queue_free()
		global_data.SETTINGS_EXIT_TYPES.SCENE:
			global_data.change_scene.emit(exit_path)
	pass



# all the actually important stuff

func create_settings_list() -> void:
	#creating list items for audio
	for bus_name in game_data.SETTINGS_RELEVANT_AUDIO_BUSES:
		var new = audio_slider_option_scene.instantiate()
		new.linked_bus_idx = AudioServer.get_bus_index(bus_name)
		settings_list.add_child(new)
		audio_slider_options.append(new)
	
	#creating list items for keybinds
	for action in global_data.get_relevant_input_actions():
		var new = keybind_option_scene.instantiate()
		new.group = keybind_button_group
		new.linked_action = action
		settings_list.add_child(new)
		keybind_options.append(new)
	
	#adding all items to the 'options' array for ease of use
	for options_array in [keybind_options, audio_slider_options, dropdown_options]:
		options.append_array(options_array)
	
	#connecting signals etc for all items in the 'options' array
	for o in options:
		o.reset_display_to_applied()
		o.connect("changed", _on_option_changed) #wID not binded bc provided by options incase it changes
		o.connect("hovered", _on_option_hovered) #wID not binded bc provided by options incase it changes
	pass

func save_then_apply_settings_list() -> void: #packs data into settingsHelper, saves it, and then reloads it
	var helper = settingsHelper.new()
	
	for bus_name in game_data.SETTINGS_RELEVANT_AUDIO_BUSES:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		var option = get_audio_slider_option_from_bus_idx(bus_idx) #doesnt check if option exists because if it didnt then it would break anyway
		helper.saved_bus_volumes.append(linear_to_db(option.last_value))
	
	var relevant_actions = global_data.get_relevant_input_actions() # all starting with SC_
	for action in relevant_actions:
		var option = get_keybind_option_from_action(action) #doesnt check if option exists because if it didnt then it would break anyway
		if option.last_input_event:
			helper.saved_events.append(option.last_input_event) #support for only ONE keybind per action
		else:
			helper.saved_events.append(null)
	
	for option in dropdown_options:
		var dropdown = option.dropdown #ease of use
		match option.get_wID():
			"WINDOW_MODE":
				helper.window_mode = dropdown.get_selected_id()
			"FPS_LIMIT":
				match dropdown.get_selected_id():
					0:
						helper.fps_limit = 0
					_:
						helper.fps_limit = dropdown.get_item_text(dropdown.get_selected()).to_int()
	
	game_data.saveSettings(helper)
	await get_tree().physics_frame
	game_data.loadThenApplySettings() #this is necessary bc of the 'instance' mode for settings_menu, wherein main_menu is not available to call this
	pass

func reset_settings_list_to_defaults() -> void:
	for option in options:
		option.reset_display_to_default() #this works for audio slider and dropdown options, but not keybind options, which are handled below!
	
	var default_events = game_data.DEFAULT_SETTINGS_RELEVANT_ACTION_EVENTS
	for i in keybind_options.size():
		var option = keybind_options[i]
		option.last_input_event = default_events[i]
	pass

# getters for the actually important stuff

func get_audio_slider_option_from_bus_idx(bus_idx: int) -> Node:
	for option in audio_slider_options:
		if option.linked_bus_idx == bus_idx:
			return option
	return null

func get_keybind_option_from_action(action: StringName) -> Node:
	for option in keybind_options:
		if option.linked_action == action:
			return option
	return null
