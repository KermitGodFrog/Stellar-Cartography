extends Control

@onready var tutorial_option_checkbox = $new_game/margin/scroll/tutorial_option_checkbox
@onready var game_type_edit = $new_game/margin/scroll/game_type_scroll/game_type_edit
@onready var name_edit = $new_game/margin/scroll/name_scroll/name_edit
@onready var ship_name_edit = $new_game/margin/scroll/ship_name_scroll/ship_name_edit


func _on_game_type_edit_item_selected(index: int) -> void:
	var meta = game_type_edit.get_item_metadata(index)
	match meta:
		global_data.GAME_INIT_TYPES.TUTORIAL:
			tutorial_option_checkbox.show()
		_:
			tutorial_option_checkbox.hide()
	pass 

func _on_name_randomizer_pressed() -> void:
	name_edit.set_text(game_data.get_random_character_name())
	pass

func _on_ship_name_randomizer_pressed() -> void:
	ship_name_edit.set_text(game_data.get_random_starship_name(game_data.UNIT_AFFILIATIONS.PROVISIONAL_EXECUTIVE).right(-3))
	pass
