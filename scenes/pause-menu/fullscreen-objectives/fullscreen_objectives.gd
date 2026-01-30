extends Control

signal exiting()

@onready var objectives_panel = $margin/objectives_panel

func _on_return_button_pressed() -> void:
	exit()
	pass 

func exit() -> void:
	emit_signal("exiting")
	queue_free()
	pass
