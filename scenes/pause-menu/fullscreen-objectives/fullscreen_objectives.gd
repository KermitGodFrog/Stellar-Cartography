extends Control

@onready var objectives_panel = $margin/objectives_panel


func _on_return_button_pressed() -> void:
	queue_free()
	pass 
