extends Control

@onready var tutorial_option_checkbox = $margin/scroll/tutorial_option_checkbox
@onready var game_type_edit = $margin/scroll/game_type_scroll/game_type_edit
@onready var name_edit = $margin/scroll/name_scroll/name_edit
@onready var ship_name_edit = $margin/scroll/ship_name_scroll/ship_name_edit
@onready var prefix_edit = $margin/scroll/prefix_edit

func initialize(_init_type: global_data.GAME_INIT_TYPES) -> void:
	match _init_type:
		global_data.GAME_INIT_TYPES.NEW:
			game_type_edit.select(0)
			game_type_edit.item_selected.emit(0)
		global_data.GAME_INIT_TYPES.TUTORIAL:
			game_type_edit.select(1)
			game_type_edit.item_selected.emit(1)
	pass

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

func get_init_data() -> Dictionary:
	var init_type: global_data.GAME_INIT_TYPES = get_init_type()
	var data: Dictionary = {}
	if (not name_edit.text.is_empty()) and (not ship_name_edit.text.is_empty()):
		data["name"] = name_edit.get_text()
		data["ship_name"] = ship_name_edit.get_text()
		data["prefix"] = prefix_edit.get_item_text(prefix_edit.selected)
	if init_type == global_data.GAME_INIT_TYPES.TUTORIAL:
		if tutorial_option_checkbox.is_pressed():
			data["tutorial_type"] = "LONG"
		else:
			data["tutorial_type"] = "SHORT"
	return data

func get_init_type() -> global_data.GAME_INIT_TYPES:
	var NEW_GAME_INIT_TYPE: global_data.GAME_INIT_TYPES = global_data.GAME_INIT_TYPES.NEW
	NEW_GAME_INIT_TYPE = game_type_edit.get_selected_metadata()
	return NEW_GAME_INIT_TYPE
