extends Control

@onready var nanites_label = $scroll/nanites_scroll/nanites_label
@onready var nanites_slider = $scroll/nanites_scroll/nanites_slider
@onready var data_value_label = $scroll/data_value_scroll/data_value_label
@onready var data_value_slider = $scroll/data_value_scroll/data_value_slider
@onready var upgrade_options = $scroll/upgrades_scroll/upgrade_options
@onready var query_scroll = $scroll/query_scroll
@onready var xp_character_options = $scroll/xp_scroll/xp_character_options
@onready var rule_name_edit = $scroll/trigger_rule_scroll/rule_name_edit

signal increasePlayerBalance(amount: int)
signal addPlayerDataValue(amount: int)

signal addPlayerHullStress(amount: int)
signal clearLoadRules()
signal revealAllWormholes()
signal revealAllBodies()
signal forceQuitDialogue()
signal forceUnexploredSystem()
signal maxCharacterStanding()
signal removePlayerMorale(amount: int)
signal quickTraverse()
signal unlockUpgrade(upgrade_idx: playerAPI.UPGRADE_ID)
signal regenerateSystem3D()
signal addCharacterXP(occupation: characterAPI.OCCUPATIONS, amount: int)


func _ready() -> void:
	_on_nanites_slider_drag_ended(true)
	_on_data_value_slider_drag_ended(true)
	for upgrade in playerAPI.UPGRADE_ID:
		upgrade_options.add_item(str(upgrade))
	for occupation in characterAPI.OCCUPATIONS:
		xp_character_options.add_item(str(occupation))
	pass

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("SC_DEBUG_OPEN_DEBUG_MENU"):
		if owner.is_visible():
			owner.hide()
		else:
			owner.move_to_center()
			owner.popup()
	pass



func _on_nanites_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		nanites_label.set_text("+%.fn" % nanites_slider.get_value())
	pass

func _on_data_value_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		data_value_label.set_text("+%.fň" % data_value_slider.get_value())
	pass

func _on_nanites_button_pressed() -> void:
	emit_signal("increasePlayerBalance", nanites_slider.get_value())
	pass

func _on_data_value_button_pressed() -> void:
	emit_signal("addPlayerDataValue", data_value_slider.get_value())
	pass

func _on_clear_load_rules_button_pressed() -> void:
	emit_signal("clearLoadRules")
	pass 

func _on_reveal_wormholes_button_pressed() -> void:
	emit_signal("revealAllWormholes")
	pass

func _on_reveal_bodies_button_pressed() -> void:
	emit_signal("revealAllBodies")
	pass

func _on_print_test_button_pressed() -> void:
	var new_query = responseQuery.new()
	new_query.add("concept", "DEBUG_printTest")
	new_query.add_tree_access("seed", randi())
	get_tree().call_group("dialogueManager", "speak", self, new_query)
	pass

func _on_query_button_pressed() -> void:
	if query_scroll.is_facts_valid() and query_scroll.is_concept_valid():
		var facts = query_scroll.facts_consolidated
		
		var new_query = responseQuery.new()
		new_query.add("concept", query_scroll.concept_consolidated)
		
		for index in facts:
			var fact: Array = facts.get(index)
			new_query.add_tree_access(fact.front(), fact.back())
		
		get_tree().call_group("dialogueManager", "speak", self, new_query)
	pass

func _on_trigger_rule_button_pressed() -> void:
	get_tree().call_group("dialogueManager", "force_trigger_rule_by_name", self, rule_name_edit.get_text())
	pass

func _on_force_quit_dialogue_button_pressed():
	emit_signal("forceQuitDialogue")
	pass

func _on_add_hull_stress_button_pressed() -> void:
	emit_signal("addPlayerHullStress", 5)
	pass

func _on_force_unexplored_system_button_pressed() -> void:
	emit_signal("forceUnexploredSystem")
	pass

func _on_max_character_standing_button_pressed() -> void:
	emit_signal("maxCharacterStanding")
	pass

func _on_remove_morale_button_pressed() -> void:
	emit_signal("removePlayerMorale", 5)
	pass

func _on_quick_traverse_button_pressed() -> void:
	emit_signal("quickTraverse")
	pass

func _on_unlock_button_pressed() -> void:
	emit_signal("unlockUpgrade", playerAPI.UPGRADE_ID.get(upgrade_options.get_item_text(upgrade_options.get_selected_id())))
	pass

func _on_add_xp_button_pressed() -> void:
	emit_signal("addCharacterXP", characterAPI.OCCUPATIONS.get(xp_character_options.get_item_text(xp_character_options.get_selected_id())), 50)
	pass

func _on_regen_system_3d_button_pressed() -> void:
	emit_signal("regenerateSystem3D")
	pass



func _on_debug_interface_window_close_requested() -> void:
	owner.hide()
	pass

func _on_debug_interface_window_about_to_popup() -> void:
	query_scroll.reset_all()
	pass
