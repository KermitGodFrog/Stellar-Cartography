extends Control

var init_type: global_data.GAME_INIT_TYPES = global_data.GAME_INIT_TYPES.NEW

@onready var inquiry_panel = $ui_margin/ui_scroll/primary_secondary_split/primary/inquiry_panel
@onready var mutations_panel = $ui_margin/ui_scroll/primary_secondary_split/secondary/mutations_panel
@onready var launch_button = $launch_button
@onready var background_animation = $background_center/background_container/background_viewport/station_ui_background/animation_player

func _ready() -> void:
	mutations_panel.connect("mutation_items_changed", _on_mutation_items_changed)
	inquiry_panel.initialize(init_type)
	
	#background
	var animations = ["starship_in_alt", "starship_in2", "starship_in3"]
	if background_animation.current_animation: animations.erase(background_animation.current_animation)
	background_animation.play("RESET")
	background_animation.play(animations.pick_random())
	pass

func _on_launch_button_pressed() -> void:
	if mutations_panel.is_launch_valid():
		var type: global_data.GAME_INIT_TYPES = inquiry_panel.get_init_type()
		var inquiry_paneL_data: Dictionary = inquiry_panel.get_init_data()
		var mutations_panel_data: Dictionary = mutations_panel.get_init_data()
		var data: Dictionary = inquiry_paneL_data.merged(mutations_panel_data)
		
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

func _on_mutation_items_changed() -> void:
	if mutations_panel != null: if launch_button != null:
		if not mutations_panel.is_launch_valid():
			launch_button.set_tooltip_text("[color=red]Mutation points MUST be above or equal to zero (0) for launch. Try installing more 'NEGATIVE' mutations, or uninstall some 'POSITIVE' mutations, to increase the points count.[/color]")
			#make the button red
		else:
			launch_button.set_tooltip_text(String())
			#make the button normal
			pass
		
	pass
