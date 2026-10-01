extends Control

var init_type: global_data.GAME_INIT_TYPES = global_data.GAME_INIT_TYPES.NEW

@onready var inquiry_panel = $ui_margin/ui_scroll/primary_secondary_split/primary/inquiry_panel
@onready var mutations_panel = $ui_margin/ui_scroll/primary_secondary_split/secondary/mutations_panel
@onready var launch_button = $launch_button
@onready var background_animation = $background_center/background_container/background_viewport/station_ui_background/animation_player
@onready var mutations_lock_panel = $ui_margin/ui_scroll/primary_secondary_split/secondary/mutations_panel/mutations_lock_panel
@onready var difficulty_scroll = $ui_margin/ui_scroll/primary_secondary_split/primary/inquiry_panel/margin/scroll/difficulty_scroll
@onready var difficulty_label = $ui_margin/ui_scroll/primary_secondary_split/primary/inquiry_panel/margin/scroll/difficulty_label

@onready var audio_handler = $audioHandler

var blur_music: bool = false

func _ready() -> void:
	#panels
	mutations_panel.connect("mutation_items_changed", _on_mutation_items_changed)
	inquiry_panel.connect("game_type_edit_changed", _on_game_type_edit_changed)
	inquiry_panel.connect("difficulty_updated", _on_difficulty_updated)
	inquiry_panel.initialize(init_type)
	
	#audio handler
	audio_handler.ambience_type = audio_handler.AMBIENCE_TYPES.CREATE_MENU
	
	var details_helper := game_data.loadUserDetails()
	if not details_helper.create_menu_this_session:
		get_tree().call_group("audioHandler", "queue_music", "res://sound/music/mission_briefing.ogg")
		details_helper.create_menu_this_session = true
	game_data.saveUserDetails(details_helper)
	
	#background
	var animations = ["starship_in_alt", "starship_in2", "starship_in3"]
	if background_animation.current_animation: animations.erase(background_animation.current_animation)
	background_animation.play("RESET")
	background_animation.play(animations.pick_random())
	pass

func _process(_delta: float) -> void:
	var mouse_in_inquiry_panel : bool = inquiry_panel.get_global_rect().has_point(get_global_mouse_position())
	var mouse_in_mutations_panel : bool = mutations_panel.get_global_rect().has_point(get_global_mouse_position())
	audio_handler.blur_music_criteria["mouse_in_blur_panels"] = mouse_in_inquiry_panel or mouse_in_mutations_panel
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
	if mutations_panel != null and launch_button != null:
		launch_button.disabled = not mutations_panel.is_launch_valid()
	pass

func _on_game_type_edit_changed(metadata: global_data.GAME_INIT_TYPES) -> void:
	match metadata:
		global_data.GAME_INIT_TYPES.TUTORIAL:
			mutations_lock_panel.visible = true
			difficulty_label.visible = false
			difficulty_scroll.visible = false
		_:
			var no_mutations_unlocked: bool = mutations_panel.get_installed_mutations().size() == 0 \
			and mutations_panel.get_uninstalled_mutation_items().size() == 0
			mutations_lock_panel.visible = no_mutations_unlocked
			difficulty_label.visible = !no_mutations_unlocked
			difficulty_scroll.visible = !no_mutations_unlocked
	pass

func _on_difficulty_updated(new_difficulty: game_data.DIFFICULTY) -> void:
	mutations_panel.current_difficulty = new_difficulty
	pass
