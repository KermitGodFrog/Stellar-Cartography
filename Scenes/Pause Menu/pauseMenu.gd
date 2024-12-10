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
			print("PAUSE MENU: CLOSING PAUSE MENU")
			pause_canvas.hide()
		game_data.PAUSE_MODES.PAUSE_MENU:
			print("PAUSE MENU: OPENING PAUSE MENU")
			can_unpause = false
			unpause_possible_timer.start()
			pause_canvas.show()
	pass



signal saveWorld
signal saveAndQuit
signal exitToMainMenu

var can_unpause = false
var is_open = false

@onready var pause_control = $pause_canvas/pause_control
@onready var unpause_possible_timer = $unpause_possible_timer
@onready var save_button = $pause_canvas/pause_control/pause_scroll/save_button
@onready var save_and_quit_button = $pause_canvas/pause_control/pause_scroll/save_and_quit_button
@onready var options_menu = $pause_canvas/options_menu
@onready var pause_canvas = $pause_canvas


func _physics_process(_delta):
	if Input.is_action_just_pressed("SC_PAUSE"):
		if can_unpause == true and _pause_mode == game_data.PAUSE_MODES.PAUSE_MENU:
			emit_signal("setPauseMode", game_data.PAUSE_MODES.NONE)
	pass

func disableSaving() -> void:
	save_button.set_disabled(true)
	save_and_quit_button.set_disabled(true)
	pass

func _on_resume_button_pressed():
	emit_signal("setPauseMode", game_data.PAUSE_MODES.NONE)
	pass

func _on_save_button_pressed():
	emit_signal("saveWorld")
	emit_signal("setPauseMode", game_data.PAUSE_MODES.NONE)
	pass

func _on_save_and_quit_button_pressed():
	emit_signal("saveAndQuit")
	emit_signal("setPauseMode", game_data.PAUSE_MODES.NONE)
	pass

func _on_exit_button_pressed():
	emit_signal("exitToMainMenu")
	emit_signal("setPauseMode", game_data.PAUSE_MODES.NONE)
	pass

func _on_unpause_possible_timer_timeout():
	can_unpause = true
	pass 

func _on_settings_button_pressed():
	options_menu.initialize()
	options_menu.visible = !options_menu.visible
	pass
