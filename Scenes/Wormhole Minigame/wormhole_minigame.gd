extends Node3D
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
			print("WORMHOLE MINIGAME: CLOSING WORMHOLE MINIGAME")
			get_node(window).hide()
		game_data.PAUSE_MODES.WORMHOLE_MINIGAME:
			print("WORMHOLE MINIGAME: OPENING WORMHOLE MINIGAME")
			get_node(window).popup()
			get_node(window).move_to_center()
	pass

signal addPlayerHullStress(amount: int)

const MAX_DISTANCE = 100.0

var upper_boundry: float = 0.0
var lower_boundry: float = 0.0
var speed: float = 0.0
var distance: float = 100.0
var hull_stress_wormhole: int = 10 #dont worry!! this value is updated every time the player traverses a wormhole - but not every frame! :> :^                                       FUCK YOU

var awaiting_start: bool = true

@export var window: NodePath

@onready var starship_and_camera = $starship_and_camera
@onready var star = $star
@onready var wormhole_interference = $wormhole_interference
@onready var deceleration = $deceleration
@onready var distance_progress = $starship_and_camera/camera/UI_control/distance_container/distance_progress
@onready var distance_upper = $starship_and_camera/camera/UI_control/distance_container/distance_upper
@onready var distance_lower = $starship_and_camera/camera/UI_control/distance_container/distance_lower
@onready var press_to_start = $starship_and_camera/camera/UI_control/press_to_start_button
@onready var brake_button = $starship_and_camera/camera/UI_control/brake_button
@onready var hull_stress_increase_label = $starship_and_camera/camera/UI_control/hull_stress_increase_label

func _physics_process(delta):
	if not awaiting_start:
		distance = maxf(0, distance - (speed * delta))
	var starship_offset = remap(distance, 0, 200, 110, 200)
	starship_and_camera.position.x = -starship_offset
	distance_progress.set_value(distance)
	
	if (distance <= 0.0) and (not awaiting_start) and (_pause_mode == game_data.PAUSE_MODES.WORMHOLE_MINIGAME):
		finish_minigame(false)
	
	wormhole_interference.stream_paused = _pause_mode != game_data.PAUSE_MODES.WORMHOLE_MINIGAME
	wormhole_interference.volume_db = linear_to_db(remap(distance, 100, 0, 0, 1))
	deceleration.stream_paused = _pause_mode != game_data.PAUSE_MODES.WORMHOLE_MINIGAME
	
	if (distance <= upper_boundry) and (distance >= lower_boundry):
		brake_button.set_theme_type_variation("BrakeGreen")
		hull_stress_increase_label.set_text("+%.f%s" % [hull_stress_wormhole, "%"])
	else:
		brake_button.set_theme_type_variation("BrakeRed")
		hull_stress_increase_label.set_text("+%.f%s" % [hull_stress_wormhole * 2, "%"])
	pass

func initialize(weirdness_index: float = 0.0, _hull_stress_wormhole: int = 10):
	distance = MAX_DISTANCE #resetting distance
	star.rotation = Vector3(global_data.get_randi(0,360), global_data.get_randi(0,360), global_data.get_randi(0,360))
	
	press_to_start.show()
	awaiting_start = true
	
	lower_boundry = clamp(randfn(50, 8) * weirdness_index, 0, 75) #normal distribution: 99.7% of lower boundries above 1 and below 49
	upper_boundry = lower_boundry + clamp(randfn((100 - lower_boundry) / 2, 8) * remap(weirdness_index, 0, 1, 1, 0), 5, (100 - lower_boundry)) #this is a really cool line of code teehee!! :>
	speed = clamp(randfn(30, 5) * weirdness_index, 2.5, 57.5)
	
	distance_upper.value = upper_boundry
	distance_lower.value = lower_boundry
	
	hull_stress_wormhole = _hull_stress_wormhole
	pass

func _on_brake_button_button_up():
	if (distance <= upper_boundry) and (distance >= lower_boundry):
		if not awaiting_start:
			finish_minigame(true)
	elif not awaiting_start:
		finish_minigame(false)
	pass

func finish_minigame(result: bool) -> void:
	awaiting_start = true
	
	match result:
		true:
			emit_signal("addPlayerHullStress", hull_stress_wormhole)
		false:
			emit_signal("addPlayerHullStress", hull_stress_wormhole * 2)
	
	emit_signal("setPauseMode", game_data.PAUSE_MODES.NONE)
	pass

func _on_press_to_start_button_pressed():
	press_to_start.hide()
	awaiting_start = false
	pass 
