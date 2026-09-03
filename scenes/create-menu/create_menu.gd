extends Control

var init_type: global_data.GAME_INIT_TYPES = global_data.GAME_INIT_TYPES.NEW

@onready var inquiry_panel = $ui_margin/ui_scroll/primary_secondary_split/primary/inquiry_panel
@onready var background_animation = $background_center/background_container/background_viewport/station_ui_background/animation_player

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
	var data: Dictionary = inquiry_panel.get_init_data()
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
