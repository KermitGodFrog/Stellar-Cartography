extends "res://Scenes/System Map/status_button.gd"

signal removeHullStressForNanites(amount: int, _nanites_per_percentage: int)

var increase_for_nanites: bool = false
var nanites_per_percentage: int = 3000


func receive_tracked_status(value):
	if not is_hovered():
		set_text(str(value))
	else:
		if increase_for_nanites == true:
			set_text("> (-1%) <")
		else:
			set_text(str(value))
	pass

func _on_upgrade_state_change(upgrade_idx: playerAPI.UPGRADE_ID, state: bool):
	if upgrade_idx == playerAPI.UPGRADE_ID.NANITE_CONTROLLER:
		increase_for_nanites = state
		print_debug("INCREASE FOR NANITES: ", increase_for_nanites)
	pass



func _on_pressed():
	if increase_for_nanites:
		emit_signal("removeHullStressForNanites", 1, nanites_per_percentage)
	pass 
