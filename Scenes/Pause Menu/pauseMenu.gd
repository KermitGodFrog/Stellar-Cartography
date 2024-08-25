extends Node

signal saveWorld
signal saveAndQuit

var can_unpause = false

@onready var pause_control = $pause_canvas/pause_control
@onready var unpause_possible_timer = $unpause_possible_timer

func _physics_process(delta):
	if Input.is_action_just_pressed("pause"):
		if can_unpause == true:
			closePauseMenu() #can_unpause is only true in the event of the openPauseMenu() function being called, but that function is never called when the dialogue or station UI is shown because game.gd, who calls the method, is paused.
	pass

func openPauseMenu():
	can_unpause = false
	unpause_possible_timer.start()
	print("PAUSE MENU: OPENING PAUSE MENU")
	pause_control.show()
	get_tree().paused = true
	pass

func closePauseMenu():
	print("PAUSE MENU: CLOSING PAUSE MENU")
	pause_control.hide()
	get_tree().paused = false
	pass



func _on_resume_button_pressed():
	closePauseMenu()
	pass


func _on_save_button_pressed():
	closePauseMenu()
	emit_signal("saveWorld")
	pass


func _on_save_and_quit_button_pressed():
	closePauseMenu()
	emit_signal("saveAndQuit")
	pass


func _on_unpause_possible_timer_timeout():
	can_unpause = true
	pass 
