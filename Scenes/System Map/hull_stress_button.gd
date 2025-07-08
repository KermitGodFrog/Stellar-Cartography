extends "res://Scenes/System Map/status_button.gd"

signal removeHullStressForNanites(amount: int, _nanites_per_percentage: int)

var increase_for_nanites: bool = false
var nanites_per_percentage: int
const default_tooltip: String = "General starship wear-and-tear. Principally may be reduced at a space station in exchange for nanites. Damage over 100% will be transferred to hull deterioration."



func _physics_process(_delta):
	nanites_per_percentage = (game_data.NANITE_CONTROLLER_REPAIR_CURVE.sample(game_data.player_weirdness_index) * 1000) #we are using too many global vars here its not very cool and stuff dont like it feel like im a rookie yknow
	
	match increase_for_nanites:
		true:
			set_tooltip_text("%s \n\n[color=red]Cost of repairing 1%% hull stress: %dn (Nanite Controller) [/color]" % [default_tooltip, nanites_per_percentage])
			if is_hovered():
				set_text("> (-1%) <") 
		false:
			set_tooltip_text(default_tooltip)
	pass

func _on_upgrade_state_change(upgrade_idx: playerAPI.UPGRADE_ID, state: bool):
	if upgrade_idx == playerAPI.UPGRADE_ID.NANITE_CONTROLLER:
		increase_for_nanites = state
		print_debug("INCREASE FOR NANITES: ", increase_for_nanites)
	pass

func _on_pressed():
	if increase_for_nanites:
		emit_signal("removeHullStressForNanites", 1, nanites_per_percentage)
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE, "eventsHandler", "speak", self, "NC_use")
	pass 
