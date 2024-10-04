extends "res://Scenes/System Map/status_button.gd"

signal removeHullStressForNanites(amount: int, _nanites_per_percentage: int)

var increase_for_nanites: bool = false
var nanites_per_percentage: int = 500

func _physics_process(_delta):
	nanites_per_percentage = (game_data.NANITE_CONTROLLER_REPAIR_CURVE.sample(game_data.player_weirdness_index) * 1000) #we are using too many global vars here its not very cool and stuff dont like it feel like im a rookie yknow
	if is_hovered() and increase_for_nanites == true:
		set_text("> (-1%) <") 
	pass

func _on_upgrade_state_change(upgrade_idx: playerAPI.UPGRADE_ID, state: bool):
	if upgrade_idx == playerAPI.UPGRADE_ID.NANITE_CONTROLLER:
		increase_for_nanites = state
		print_debug("INCREASE FOR NANITES: ", increase_for_nanites)
	pass

func _on_pressed():
	if increase_for_nanites: emit_signal("removeHullStressForNanites", 1, nanites_per_percentage)
	pass 
