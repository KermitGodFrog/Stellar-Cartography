extends Node

signal onCloseStatsMenu()

@onready var stats_control = $stats_canvas/stats_control
@onready var systems_traversed_label = $stats_canvas/stats_control/main_scroll/systems_traversed_label
@onready var init_type_label = $stats_canvas/stats_control/main_scroll/init_type_label
enum INIT_TYPES {DEATH, WIN}


func openStatsMenu(init_type: INIT_TYPES, player_systems_traversed: int):
	match init_type:
		INIT_TYPES.DEATH:
			init_type_label.set_text("YOU ARE DEAD")
		INIT_TYPES.WIN:
			init_type_label.set_text("YOU HAVE REACHED NEW EDEN")
	systems_traversed_label.set_text(str("SYSTEMS DISCOVERED: ", player_systems_traversed))
	print("STATS MENU: OPENING STATS MENU")
	stats_control.show()
	get_tree().paused = true
	pass

func closeStatsMenu():
	stats_control.hide()
	get_tree().paused = false
	emit_signal("onCloseStatsMenu")
	pass

func _on_exit_to_main_menu_button_pressed():
	closeStatsMenu()
	pass 
