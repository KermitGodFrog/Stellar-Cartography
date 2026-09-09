extends HBoxContainer

@onready var game_type_edit = $game_type_edit
@onready var game_type_info = $game_type_info

const game_type_descriptions: Dictionary = {
	global_data.GAME_INIT_TYPES.NEW: "--CAMPAIGN--\nPlay [i]Stellar Cartographer[/i].",
	global_data.GAME_INIT_TYPES.TUTORIAL: "--TUTORIAL--\nLearn how to play [i]Stellar Cartographer[/i]."
}

func _ready() -> void:
	game_type_edit.add_item("CAMPAIGN")
	game_type_edit.add_item("TUTORIAL")
	game_type_edit.set_item_metadata(0, global_data.GAME_INIT_TYPES.NEW)
	game_type_edit.set_item_metadata(1, global_data.GAME_INIT_TYPES.TUTORIAL)
	game_type_edit.select(0)
	_on_game_type_edit_item_selected(0)
	pass

func _on_game_type_edit_item_selected(index: int) -> void:
	game_type_info.clear()
	var metadata = game_type_edit.get_item_metadata(index)
	var description = game_type_descriptions.get(metadata)
	game_type_info.append_text(description)
	pass 
