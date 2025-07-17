extends Control

@onready var continue_button = $options_scroll/continue_button
@onready var new_button = $options_scroll/new_button
@onready var create_button = $new_game_popup/new_game/margin/scroll/create_button
@onready var name_edit = $new_game_popup/new_game/margin/scroll/name_edit
@onready var prefix_edit = $new_game_popup/new_game/margin/scroll/prefix_edit
@onready var new_game_popup = $new_game_popup
@onready var achievements_list_popup = $achievements_list_popup
@onready var background = $background

var SHOW_NEW_GAME_POPUP: bool = false:
	set(value):
		SHOW_NEW_GAME_POPUP = value
		if value == true:
			new_game_popup.show()
		elif value == false:
			new_game_popup.hide()
var SHOW_ACHIEVEMENTS_LIST_POPUP: bool = false:
	set(value):
		SHOW_ACHIEVEMENTS_LIST_POPUP = value
		if value == true:
			achievements_list_popup.show()
		if value == false:
			achievements_list_popup.hide()

const background_images: Array = [
	preload("res://Graphics/Dialogue/SA03G_seeder_ship_OFF.png"),
	preload("res://Graphics/Dialogue/PA_04_missing_core.png")
]

func _ready():
	achievements_list_popup.connect("returnButtonPressed", _on_achievements_list_return_button_pressed)
	background.set_texture(ImageTexture.create_from_image(background_images.pick_random()))
	
	if ResourceLoader.exists("user://stellar_cartographer_data.res"):
		continue_button.disabled = false
	
	#setting defaults - has to be done  before because helper might not exist, and so defaults qwould not be set!
	var relevant_actions = global_data.get_relevant_input_actions()
	for i in relevant_actions.size():
		var action = relevant_actions[i]
		var event = InputMap.action_get_events(action)
		if not event.is_empty():
			game_data.DEFAULT_SETTINGS_RELEVANT_ACTION_EVENTS.append(event.front())
		else:
			game_data.DEFAULT_SETTINGS_RELEVANT_ACTION_EVENTS.append(null)
	
	var helper = game_data.loadSettings()
	if helper != null:
		#loading audio
		var relevant_audio_buses = game_data.SETTINGS_RELEVANT_AUDIO_BUSES
		var volumes_same_size: bool = relevant_audio_buses.size() == helper.saved_bus_volumes.size()
		for i in relevant_audio_buses.size():
			var bus_name = game_data.SETTINGS_RELEVANT_AUDIO_BUSES[i]
			var bus_idx = AudioServer.get_bus_index(bus_name)
			
			if volumes_same_size:
				AudioServer.set_bus_volume_db(bus_idx, helper.saved_bus_volumes[i])
		
		#loading inputs - relevant_actions moved upwards because helper might not exist teehee
		var events_same_size: bool = relevant_actions.size() == helper.saved_events.size() #if an update comes along and adds keybinds, everything is reset to defaults
		for i in relevant_actions.size():
			var action = relevant_actions[i]
			
			if events_same_size:
				InputMap.action_erase_events(action)
				InputMap.action_add_event(action, helper.saved_events[i])
	pass

func _on_continue_button_pressed():
	global_data.change_scene.emit("res://Scenes/Game/game.tscn", {"init_type": global_data.GAME_INIT_TYPES.CONTINUE})
	pass

func _on_tutorial_button_pressed():
	global_data.change_scene.emit("res://Scenes/Game/game.tscn", {"init_type": global_data.GAME_INIT_TYPES.TUTORIAL})
	pass

func _on_create_button_pressed():
	if not name_edit.text.is_empty():
		global_data.change_scene.emit("res://Scenes/Game/game.tscn", {
			"init_type": global_data.GAME_INIT_TYPES.NEW, 
			"init_data": {"name": name_edit.get_text(), "prefix": prefix_edit.get_item_text(prefix_edit.selected)}
			})
	else:
		global_data.change_scene.emit("res://Scenes/Game/game.tscn", {
			"init_type": global_data.GAME_INIT_TYPES.NEW})
	pass

func _on_new_button_pressed():
	SHOW_NEW_GAME_POPUP = true
	pass

func _on_new_game_return_button_pressed():
	SHOW_NEW_GAME_POPUP = false
	pass

func _on_achievements_button_pressed():
	SHOW_ACHIEVEMENTS_LIST_POPUP = true
	pass

func _on_achievements_list_return_button_pressed(): #connects in _ready
	SHOW_ACHIEVEMENTS_LIST_POPUP = false
	pass
