extends Control

var init_type: global_data.GAME_INIT_TYPES = global_data.GAME_INIT_TYPES.NEW

@onready var inquiry_panel = $ui_margin/ui_scroll/primary_secondary_split/primary/inquiry_panel
@onready var background_animation = $background_center/background_container/background_viewport/station_ui_background/animation_player

const mutation_data: Dictionary = {
	worldAPI.MUTATION_ID.CONTENT_SKALIQ: {
		"title": "Content: The Skaliq",
		"headline": "A species of alien worms that are often encountered in deep space.",
		"description": "These sapient aliens, originating from the rings of a gas giant, are as devoted to exploration and pioneering as humans are. A skaliq colony is known to have coexisted with human residents of the Mashdari system since they arrived during the Late Proliferation. Once Mashdari was reconciled in 27AAT, those same residents shared Arata's theorem with their skaliq counterparts. Besides the few similarities, humans are very different to these aliens - beware of miscommunications.",
		"effect": "Adds 6 planetary anomalies, 6 space anomalies, 3 ship encounters, and other content."
	},
	worldAPI.MUTATION_ID.OLD_NANITES: {
		"title": "Old Nanites",
		"headline": "An alternate universe where an outdated nanite design is universal.",
		"description": "In this alternate universe, the Provisional Executive never developed the Modern Era nanite in 14AAT. Reliance on the outdated 'universal nanite' carried by seeder ships during the latter half of the Late Proliferation Period continued instead.",
		"effect": "Repairing at space stations and settlements costs +50% more."
	}
}

func _ready() -> void:
	inquiry_panel.initialize(init_type)
	
	#background
	var animations = ["starship_in_alt", "starship_in2", "starship_in3"]
	if background_animation.current_animation: animations.erase(background_animation.current_animation)
	background_animation.play("RESET")
	background_animation.play(animations.pick_random())
	pass


func _on_launch_button_pressed() -> void:
	var type: global_data.GAME_INIT_TYPES = inquiry_panel.get_init_type()
	var inquiry_data: Dictionary = inquiry_panel.get_init_data()
	var mutations_data: Dictionary = {"mutations": []}
	var data: Dictionary = inquiry_data.merged(mutations_data)
	
	if data.size() > 0:
		global_data.change_scene.emit("res://scenes/game/game.tscn", {
			"init_type": type, 
			"init_data": data
			})
	else:
		global_data.change_scene.emit("res://scenes/game/game.tscn", {
			"init_type": type
		})
	pass

func _on_return_button_pressed() -> void:
	global_data.change_scene.emit("res://scenes/main-menu/main_menu.tscn")
	pass
