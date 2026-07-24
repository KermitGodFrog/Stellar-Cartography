extends Control

@onready var continue_button = $options_scroll/continue_button
@onready var new_button = $options_scroll/new_button
@onready var create_button = $new_game_popup/new_game/margin/scroll/create_button
@onready var name_edit = $new_game_popup/new_game/margin/scroll/name_scroll/name_edit
@onready var prefix_edit = $new_game_popup/new_game/margin/scroll/prefix_edit
@onready var ship_name_edit = $new_game_popup/new_game/margin/scroll/ship_name_scroll/ship_name_edit
@onready var game_type_edit = $new_game_popup/new_game/margin/scroll/game_type_scroll/game_type_edit
@onready var tutorial_option_checkbox = $new_game_popup/new_game/margin/scroll/tutorial_option_checkbox
@onready var new_game_popup = $new_game_popup
@onready var achievements_list_popup = $achievements_list_popup
@onready var background = $background
@onready var credits_popup = $credits_popup
@onready var history_popup = $history_popup

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
var SHOW_CREDITS_POPUP: bool = false:
	set(value):
		SHOW_CREDITS_POPUP = value
		if value == true:
			credits_popup.show()
		if value == false:
			credits_popup.hide()
var SHOW_HISTORY_POPUP: bool = false:
	set(value):
		SHOW_HISTORY_POPUP = value
		if value == true:
			history_popup.show()
		if value == false:
			history_popup.hide()

var NEW_GAME_INIT_TYPE: global_data.GAME_INIT_TYPES = global_data.GAME_INIT_TYPES.NEW

const background_images: Array = [
	preload("uid://y2kguswkl4v4"),
	preload("uid://p0yhaer28ulk")
]

func _ready():
	achievements_list_popup.connect("returnButtonPressed", _on_achievements_list_return_button_pressed)
	history_popup.connect("returnButtonPressed", _on_history_return_button_pressed)
	background.set_texture(ImageTexture.create_from_image(background_images.pick_random()))
	
	if ResourceLoader.exists("user://stellar_cartographer_data.res"):
		continue_button.disabled = false
	
	game_data.loadThenApplySettings()
	pass

func _on_continue_button_pressed():
	global_data.change_scene.emit("res://scenes/game/game.tscn", {"init_type": global_data.GAME_INIT_TYPES.CONTINUE})
	pass

func _on_create_button_pressed():
	NEW_GAME_INIT_TYPE = game_type_edit.get_selected_metadata()
	var data: Dictionary = {}
	if (not name_edit.text.is_empty()) and (not ship_name_edit.text.is_empty()):
		data["name"] = name_edit.get_text()
		data["ship_name"] = ship_name_edit.get_text()
		data["prefix"] = prefix_edit.get_item_text(prefix_edit.selected)
	if NEW_GAME_INIT_TYPE == global_data.GAME_INIT_TYPES.TUTORIAL:
		if tutorial_option_checkbox.is_pressed():
			data["tutorial_type"] = "LONG"
		else:
			data["tutorial_type"] = "SHORT"
	
	if data.size() > 0:
		global_data.change_scene.emit("res://scenes/game/game.tscn", {
			"init_type": NEW_GAME_INIT_TYPE, 
			"init_data": data
			})
	else:
		global_data.change_scene.emit("res://scenes/game/game.tscn", {
			"init_type": NEW_GAME_INIT_TYPE
		})
	pass

func _on_new_button_pressed():
	game_type_edit.select(0)
	game_type_edit.item_selected.emit(0)
	SHOW_NEW_GAME_POPUP = true
	pass

func _on_tutorial_button_pressed() -> void:
	game_type_edit.select(1)
	game_type_edit.item_selected.emit(1)
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

func _on_credits_button_pressed() -> void:
	SHOW_CREDITS_POPUP = true
	pass

func _on_credits_return_button_pressed() -> void:
	SHOW_CREDITS_POPUP = false
	pass

func _on_history_button_pressed() -> void:
	SHOW_HISTORY_POPUP = true
	pass

func _on_history_return_button_pressed() -> void:
	SHOW_HISTORY_POPUP = false
	pass

func _on_settings_button_pressed() -> void:
	global_data.change_scene.emit("res://scenes/settings-menu/settings_menu.tscn", {
		"exit_type": global_data.SETTINGS_EXIT_TYPES.SCENE,
		"exit_path": "res://scenes/main-menu/main_menu.tscn"
	})
	pass
