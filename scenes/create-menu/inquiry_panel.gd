extends Control

signal game_type_edit_changed(metadata: global_data.GAME_INIT_TYPES)
signal difficulty_updated(new_difficulty: game_data.DIFFICULTY)

@onready var tutorial_option_checkbox = $margin/scroll/tutorial_option_checkbox
@onready var game_type_edit = $margin/scroll/game_type_scroll/game_type_edit
@onready var name_edit = $margin/scroll/name_scroll/name_edit
@onready var ship_name_edit = $margin/scroll/ship_name_scroll/ship_name_edit
@onready var prefix_edit = $margin/scroll/prefix_edit
@onready var difficulty_scroll = $margin/scroll/difficulty_scroll
@onready var NORMAL_difficulty_button = $margin/scroll/difficulty_scroll/NORMAL

@onready var difficulty_button_group = preload("uid://cud8x6w2c27kt")

func _ready() -> void:
	connect("game_type_edit_changed", _on_game_type_edit_changed)
	for child in difficulty_scroll.get_children():
		child.button_group = difficulty_button_group
	difficulty_button_group.pressed.connect(_on_difficulty_button_pressed)
	pass

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
	emit_signal("game_type_edit_changed", game_type_edit.get_item_metadata(index))
	pass 

func _on_game_type_edit_changed(metadata: global_data.GAME_INIT_TYPES) -> void:
	match metadata:
		global_data.GAME_INIT_TYPES.TUTORIAL:
			tutorial_option_checkbox.show()
		_:
			tutorial_option_checkbox.hide()
	reset_difficulty()
	pass

func _on_difficulty_button_pressed(button: BaseButton) -> void:
	emit_signal("difficulty_updated", get_difficulty_from_name(button.get_name()))
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
	data["difficulty"] = get_difficulty_from_name(difficulty_button_group.get_pressed_button().get_name())
	return data

func get_init_type() -> global_data.GAME_INIT_TYPES:
	var NEW_GAME_INIT_TYPE: global_data.GAME_INIT_TYPES = global_data.GAME_INIT_TYPES.NEW
	NEW_GAME_INIT_TYPE = game_type_edit.get_selected_metadata()
	return NEW_GAME_INIT_TYPE




func reset_difficulty() -> void:
	NORMAL_difficulty_button.set_pressed(true)
	pass

func get_difficulty_from_name(base_name: StringName) -> game_data.DIFFICULTY:
	return game_data.DIFFICULTY.get(base_name, game_data.DIFFICULTY.NORMAL)
