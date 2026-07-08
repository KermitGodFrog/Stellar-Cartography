extends Control

@onready var tutorial_option_checkbox = $new_game/margin/scroll/tutorial_option_checkbox
@onready var game_type_edit = $new_game/margin/scroll/game_type_scroll/game_type_edit

func _on_game_type_edit_item_selected(index: int) -> void:
	var meta = game_type_edit.get_item_metadata(index)
	match meta:
		global_data.GAME_INIT_TYPES.TUTORIAL:
			tutorial_option_checkbox.show()
		_:
			tutorial_option_checkbox.hide()
	pass 
