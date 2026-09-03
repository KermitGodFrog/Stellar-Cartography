extends Control

@onready var continue_button = $options_scroll/continue_button
@onready var new_button = $options_scroll/new_button
@onready var achievements_list_popup = $achievements_list_popup
@onready var credits_popup = $credits_popup
@onready var history_popup = $history_popup
@onready var background = $background

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
	global_data.change_scene.emit("res://scenes/game/game.tscn", {
		"init_type": global_data.GAME_INIT_TYPES.CONTINUE
	})
	pass

func _on_new_button_pressed():
	global_data.change_scene.emit("res://scenes/run-creation-menu/run_creation_menu.tscn", {
		"init_type": global_data.GAME_INIT_TYPES.NEW
	})
	pass

func _on_tutorial_button_pressed() -> void:
	global_data.change_scene.emit("res://scenes/run-creation-menu/run_creation_menu.tscn", {
		"init_type": global_data.GAME_INIT_TYPES.TUTORIAL
	})
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
