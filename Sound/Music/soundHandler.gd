extends Node

@onready var play_timer = $play_timer
@onready var music = $music

@onready var ui_click_sound_scene = preload("res://Sound/button_press.tscn")

#needs to duck for dialogue!
#should be always active and just not play some SFX when game is paused!

func _ready():
	var SFX_buttons = get_tree().get_nodes_in_group("playUIClickSFX")
	for button in SFX_buttons:
		if button is Button:
			button.connect("pressed", _on_UI_click_SFX_button_pressed)
		if button is TabContainer:
			button.connect("tab_button_pressed", _on_UI_click_SFX_button_pressed)
		if button is ItemList:
			button.connect("item_selected", _on_UI_click_SFX_button_pressed)
	
	play_timer.start(global_data.get_randi(60, 360))
	pass

func _on_play_timer_timeout():
	$music.play()
	play_timer.start(global_data.get_randi(60, 360))
	pass

func _on_UI_click_SFX_button_pressed(_tab_or_item_index = null) -> void:
	async_play_ui_click_SFX()
	pass

func async_play_ui_click_SFX() -> void:
	var SFX_instance = ui_click_sound_scene.instantiate()
	add_child(SFX_instance)
	SFX_instance.play()
	await SFX_instance.finished
	SFX_instance.queue_free()
	pass
