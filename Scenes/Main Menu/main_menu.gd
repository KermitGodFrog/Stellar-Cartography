extends Control

@onready var continue_button = $continue_button
@onready var new_button = $new_button
@onready var create_button = $new_game_popup/new_game/margin/scroll/create_button
@onready var name_edit = $new_game_popup/new_game/margin/scroll/name_edit
@onready var prefix_edit = $new_game_popup/new_game/margin/scroll/prefix_edit
@onready var new_game_popup = $new_game_popup

var SHOW_NEW_GAME_POPUP: bool = false:
	set(value):
		SHOW_NEW_GAME_POPUP = value
		if value == true:
			$new_game_popup.show()
		elif value == false:
			$new_game_popup.hide()

func _ready():
	if ResourceLoader.exists("user://stellar_cartographer_data.res"):
		continue_button.disabled = false
	pass

func _on_continue_button_pressed():
	global_data.change_scene.emit("res://Scenes/Game/game.tscn", global_data.GAME_INIT_TYPES.CONTINUE)
	pass

func _on_tutorial_button_pressed():
	global_data.change_scene.emit("res://Scenes/Game/game.tscn", global_data.GAME_INIT_TYPES.TUTORIAL)
	pass

func _on_create_button_pressed():
	global_data.change_scene.emit("res://Scenes/Game/game.tscn", global_data.GAME_INIT_TYPES.NEW, {"name": name_edit.text, "prefix": prefix_edit.get_item_text(prefix_edit.selected)})
	pass

func _on_new_button_pressed():
	SHOW_NEW_GAME_POPUP = true
	pass

func _on_return_button_pressed():
	SHOW_NEW_GAME_POPUP = false
	pass
