extends Control

@onready var continue_button = $continue_button
@onready var new_button = $new_button

func _ready():
	if ResourceLoader.exists("user://stellar_cartographer_data.tres"):
		continue_button.disabled = false
	pass


func _on_continue_button_pressed():
	global_data.change_scene.emit("res://Scenes/Game/game.tscn")
	pass

func _on_new_button_pressed():
	global_data.change_scene.emit("res://Scenes/Game/game.tscn")
	pass 
