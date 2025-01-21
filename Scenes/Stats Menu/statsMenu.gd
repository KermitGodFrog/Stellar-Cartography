extends Node

var _pause_mode: game_data.PAUSE_MODES = game_data.PAUSE_MODES.NONE:
	set(value):
		_pause_mode = value
		_on_pause_mode_changed(value)
signal queuePauseMode(new_mode: game_data.PAUSE_MODES)
signal setPauseMode(new_mode: game_data.PAUSE_MODES)
func _on_pause_mode_changed(value):
	match value:
		game_data.PAUSE_MODES.NONE:
			print("STATS MENU: CLOSING STATS MENU")
			stats_control.hide()
		game_data.PAUSE_MODES.STATS_MENU:
			print("STATS MENU: OPENING STATS MENU")
			match init_type:
				INIT_TYPES.DEATH:
					init_type_label.set_text("YOU ARE DEAD")
				INIT_TYPES.WIN:
					init_type_label.set_text("YOU HAVE REACHED NEW EDEN")
				INIT_TYPES.TUTORIAL:
					init_type_label.set_text("YOU HAVE COMPLETED THE TUTORIAL")
			systems_traversed_label.set_text("SCORE: %.f" % _player_score)
			stats_control.show()
	pass



signal statsMenuQuit(_init_type: INIT_TYPES)

@onready var stats_control = $stats_canvas/stats_control
@onready var systems_traversed_label = $stats_canvas/stats_control/main_panel/main_scroll/systems_traversed_label
@onready var init_type_label = $stats_canvas/stats_control/main_panel/main_scroll/init_type_label
enum INIT_TYPES {DEATH, WIN, TUTORIAL}
var init_type: INIT_TYPES = INIT_TYPES.DEATH
var _player_score: int = 0

func _on_exit_to_main_menu_button_pressed():
	emit_signal("statsMenuQuit", init_type)
	emit_signal("setPauseMode", game_data.PAUSE_MODES.NONE)
	pass 
