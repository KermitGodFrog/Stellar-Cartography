extends Control

var init_type: global_data.TITLE_SCREEN_INIT_TYPES = global_data.TITLE_SCREEN_INIT_TYPES.RETURNING_PLAYER

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("SC_LOAD_CONFIRMATION"):
		match init_type:
			global_data.TITLE_SCREEN_INIT_TYPES.RETURNING_PLAYER:
				global_data.change_scene.emit("res://scenes/main-menu/main_menu.tscn")
			global_data.TITLE_SCREEN_INIT_TYPES.NEW_PLAYER:
				global_data.change_scene.emit("res://scenes/create-menu/create_menu.tscn", {
					"init_type": global_data.GAME_INIT_TYPES.TUTORIAL
				})
	pass
