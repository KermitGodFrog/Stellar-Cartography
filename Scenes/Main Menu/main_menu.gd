extends Control

@onready var continue_button = $continue_button
@onready var new_button = $new_button
@onready var name_edit = $name_edit
@onready var prefix_edit = $prefix_edit

func _ready():
	if ResourceLoader.exists("user://stellar_cartographer_data.res"):
		continue_button.disabled = false
	pass


func _on_continue_button_pressed():
	global_data.change_scene.emit("res://Scenes/Game/game.tscn", global_data.GAME_INIT_TYPES.CONTINUE)
	pass

func _on_new_button_pressed():
	global_data.change_scene.emit("res://Scenes/Game/game.tscn", global_data.GAME_INIT_TYPES.NEW, {"name": name_edit.text, "prefix": prefix_edit.get_item_text(prefix_edit.selected)})
	pass 
