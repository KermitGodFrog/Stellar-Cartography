extends Control

@onready var nanites_label = $scroll/nanites_scroll/nanites_label
@onready var nanites_slider = $scroll/nanites_scroll/nanites_slider


signal increasePlayerBalance(amount: int)

signal clearLoadRules()
signal revealAllWormholes()
signal revealAllBodies()
signal printTest()


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
	emit_signal("printTest")
	pass








func _on_debug_interface_window_close_requested() -> void:
	owner.hide()
	pass
