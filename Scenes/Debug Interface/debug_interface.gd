extends Control

@onready var nanites_label = $scroll/nanites_scroll/nanites_label
@onready var nanites_slider = $scroll/nanites_scroll/nanites_slider
@onready var query_scroll = $scroll/query_scroll


signal increasePlayerBalance(amount: int)

signal clearLoadRules()
signal revealAllWormholes()
signal revealAllBodies()
signal forceQuitDialogue()


func _ready() -> void:
	_on_nanites_slider_drag_ended(true)
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

func _on_nanites_button_pressed() -> void:
	emit_signal("increasePlayerBalance", nanites_slider.get_value())
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

func _on_force_quit_dialogue_button_pressed():
	emit_signal("forceQuitDialogue")
	pass



func _on_debug_interface_window_close_requested() -> void:
	owner.hide()
	pass

func _on_debug_interface_window_about_to_popup() -> void:
	query_scroll.reset_all()
	pass
