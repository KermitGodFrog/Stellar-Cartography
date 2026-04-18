extends Node3D
#this class is so beautiful... i can always find exactly what im looking for so so easily... its so simple and small and awesome... i love you wormhole_minigame.gd... 
#sounds WILL play whenever the game is paused, regardless of whether the window is shown or not!

var _pause_mode: game_data.PAUSE_MODES = game_data.PAUSE_MODES.NONE:
	set(value):
		_pause_mode = value
		_on_pause_mode_changed(value)
signal queuePauseMode(new_mode: game_data.PAUSE_MODES)
signal setPauseMode(new_mode: game_data.PAUSE_MODES)
func _on_pause_mode_changed(value):
	match value:
		game_data.PAUSE_MODES.NONE:
			get_node(window).hide()
		game_data.PAUSE_MODES.WORMHOLE_MINIGAME:
			get_node(window).popup()
			get_node(window).move_to_center()
	pass

signal addPlayerHullStress(amount: int)

const MAX_DISTANCE = 100.0

enum RESULTS {SUCCESS, FAILURE, SPECIAL}

var upper_boundary: float = 0.0
var lower_boundary: float = 0.0
var special_upper_boundary: float = 0.0
var special_lower_boundary: float = 0.0
var speed: float = 0.0
var distance: float = 100.0
var hull_stress_wormhole: int = 10 #dont worry!! this value is updated every time the player traverses a wormhole - but not every frame! :> :^                                       FUCK YOU

var awaiting_start: bool = true

@export var window: NodePath

@onready var star = $star
@onready var starship_and_camera = $starship_and_camera
@onready var wormhole_interference = $wormhole_interference
@onready var deceleration = $deceleration
@onready var distance_progress = $starship_and_camera/camera/UI_control/distance_container/label_boundary_scroll/boundary_container/distance_progress
@onready var boundaries = $starship_and_camera/camera/UI_control/distance_container/label_boundary_scroll/boundary_container/boundaries
@onready var press_to_start = $starship_and_camera/camera/UI_control/press_to_start_button
@onready var brake_button = $starship_and_camera/camera/UI_control/brake_button
@onready var hull_stress_increase_label = $starship_and_camera/camera/UI_control/hint_scroll/hull_stress_increase_label
@onready var hint_scroll = $starship_and_camera/camera/UI_control/hint_scroll
@onready var tutorial = $starship_and_camera/camera/UI_control/tutorial
@onready var red_label = $starship_and_camera/camera/UI_control/red_label
@onready var green_label = $starship_and_camera/camera/UI_control/green_label
@onready var cyan_label = $starship_and_camera/camera/UI_control/cyan_label

@onready var failure_sound = preload("uid://bplalt1pic5f")
@onready var success_sound = preload("uid://c6aiafgr21bxi")

func _physics_process(delta):
	if not awaiting_start:
		distance = maxf(0, distance - (speed * delta))
	var starship_offset = remap(distance, 0, 200, 110, 200)
	starship_and_camera.position.x = -starship_offset
	distance_progress.set_value(distance)
	
	hint_scroll.set_global_position(Vector2(distance_progress.global_position.x + (distance_progress.size.x + 4), distance_progress.global_position.y + remap(distance, 100.0, 0.0, 0.0, distance_progress.size.y) - hint_scroll.size.y / 2))
	
	if (distance <= 0.0) and (not awaiting_start) and (_pause_mode == game_data.PAUSE_MODES.WORMHOLE_MINIGAME):
		finish_minigame(RESULTS.FAILURE)
	
	wormhole_interference.stream_paused = _pause_mode != game_data.PAUSE_MODES.WORMHOLE_MINIGAME
	wormhole_interference.volume_db = linear_to_db(remap(distance, 100, 0, 0, 1))
	deceleration.stream_paused = _pause_mode != game_data.PAUSE_MODES.WORMHOLE_MINIGAME
	
	if (distance <= special_upper_boundary) and (distance >= special_lower_boundary):
		brake_button.set_theme_type_variation("BrakeCyan")
		hull_stress_increase_label.set_text("+%.f%s" % [hull_stress_wormhole - 5, "%"])
	elif (distance <= upper_boundary) and (distance >= lower_boundary):
		brake_button.set_theme_type_variation("BrakeGreen")
		hull_stress_increase_label.set_text("+%.f%s" % [hull_stress_wormhole, "%"])
	else:
		brake_button.set_theme_type_variation("BrakeRed")
		hull_stress_increase_label.set_text("+%.f%s" % [hull_stress_wormhole * 2, "%"])
	pass

func initialize(weirdness_index: float = 0.0, _hull_stress_wormhole: int = 0):
	distance = MAX_DISTANCE #resetting distance
	star.rotation = Vector3(global_data.get_randi(0,360), global_data.get_randi(0,360), global_data.get_randi(0,360))
	
	press_to_start.show()
	awaiting_start = true
	
	lower_boundary = clamp(randfn(50, 8) * weirdness_index, 1, 75) #normal distribution: 99.7% of lower boundries above 1 and below 49
	upper_boundary = lower_boundary + clamp(randfn((100 - lower_boundary) / 2, 8) * remap(weirdness_index, 0, 1, 1, 0), 5, (100 - lower_boundary)) #this is a really cool line of code teehee!! :>
	special_upper_boundary = clamp(global_data.get_randf(1, lower_boundary), 1, lower_boundary)
	special_lower_boundary = clamp(special_upper_boundary - randfn(1.125, 0.25), 0.0, special_upper_boundary - 1.0)
	speed = clamp(randfn(30, 5) * weirdness_index, 2.5, 57.5)
	
	#DARK CYAN: #00c3c3
	var gradient := Gradient.new()
	gradient.set_interpolation_mode(Gradient.GRADIENT_INTERPOLATE_CONSTANT)
	gradient.set_color(0, Color("#bf3f3f")) #Color.RED desaturated 50%: #bf3f3f
	gradient.remove_point(1)
	gradient.add_point(get_gradient_boundary(upper_boundary), Color("#3fbf3f")) #Color.GREEN desaturated 50%: #3fbf3f
	gradient.add_point(get_gradient_boundary(lower_boundary), Color("#bf3f3f"))
	gradient.add_point(get_gradient_boundary(special_upper_boundary), Color("#309292")) #Color.DARK_CYAN desaturated 50%: #309292
	if special_lower_boundary == 0.0:
		gradient.add_point(get_gradient_boundary(special_lower_boundary), Color("#309292"))
	else:
		gradient.add_point(get_gradient_boundary(special_lower_boundary), Color("#bf3f3f"))
		gradient.add_point(1.0, Color("#bf3f3f"))
	
	var texture := GradientTexture2D.new()
	texture.set_gradient(gradient)
	texture.set_width(20)
	texture.set_height(200)
	texture.set_fill_to(Vector2(0, 1))
	
	boundaries.set_under_texture(texture)
	
	hull_stress_wormhole = _hull_stress_wormhole
	
	update_boundary_labels()
	pass

func _on_brake_button_button_up():
	if (distance <= special_upper_boundary) and (distance >= special_lower_boundary):
		if not awaiting_start:
			finish_minigame(RESULTS.SPECIAL)
	elif (distance <= upper_boundary) and (distance >= lower_boundary):
		if not awaiting_start:
			finish_minigame(RESULTS.SUCCESS)
	elif not awaiting_start:
		finish_minigame(RESULTS.FAILURE)
	pass

func finish_minigame(result: RESULTS) -> void:
	awaiting_start = true
	
	match result:
		RESULTS.SUCCESS:
			emit_signal("addPlayerHullStress", hull_stress_wormhole)
			get_tree().call_group("audioHandler", "play_once", success_sound, -6, "SFX")
			get_tree().call_group("audioHandler", "plot_radio", load("uid://d4dv8lmqyeb0b"))
		RESULTS.FAILURE:
			emit_signal("addPlayerHullStress", hull_stress_wormhole * 2)
			get_tree().call_group("audioHandler", "play_once", failure_sound, -6, "SFX")
			get_tree().call_group("audioHandler", "plot_radio", load("uid://bw3fyxwdtfqyi"))
		RESULTS.SPECIAL:
			emit_signal("addPlayerHullStress", hull_stress_wormhole - 5)
			get_tree().call_group("audioHandler", "play_once", success_sound, -6, "SFX")
			get_tree().call_group("audioHandler", "plot_radio", load("uid://d4dv8lmqyeb0b"))
	
	emit_signal("setPauseMode", game_data.PAUSE_MODES.NONE)
	pass

func _on_press_to_start_button_pressed():
	press_to_start.hide()
	awaiting_start = false
	pass 

func _on_set_tutorial_visible(value: bool) -> void:
	tutorial.set_visible(value)
	pass

#misc

func get_gradient_boundary(boundary: float) -> float:
	return remap(boundary, 0, 100, 100, 0) / 100.0

func update_boundary_labels() -> void:
	#this the most ugly thing of all time BLEHHHHH
	green_label.set_text("%.f%%" % (hull_stress_wormhole))
	red_label.set_text("%.f%%" % (hull_stress_wormhole * 2))
	cyan_label.set_text("%.f%%" % (hull_stress_wormhole - 5))
	
	green_label.set_global_position(Vector2(distance_progress.global_position.x - (green_label.size.x + 7), distance_progress.global_position.y + remap(upper_boundary, 100.0, 0.0, 0.0, distance_progress.size.y) - red_label.size.y / 2))
	red_label.set_global_position(Vector2(distance_progress.global_position.x - (red_label.size.x + 7), distance_progress.global_position.y - red_label.size.y / 2))
	cyan_label.set_global_position(Vector2(distance_progress.global_position.x - (cyan_label.size.x + 7), distance_progress.global_position.y + remap(special_upper_boundary, 100.0, 0.0, 0.0, distance_progress.size.y) - red_label.size.y / 2))
	pass
