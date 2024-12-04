extends Node3D

signal finishWormholeMinigame
signal addPlayerHullStress(amount: int)

const MAX_DISTANCE = 100.0

var upper_boundry: float = 0.0
var lower_boundry: float = 0.0
var speed: float = 0.0
var distance: float = 100.0
var hull_stress_wormhole: int = 10

var awaiting_start: bool = true

@onready var starship_and_camera = $starship_and_camera
@onready var distance_progress = $starship_and_camera/camera/UI_control/distance_container/distance_progress

@onready var distance_upper = $starship_and_camera/camera/UI_control/distance_container/distance_upper
@onready var distance_lower = $starship_and_camera/camera/UI_control/distance_container/distance_lower

@onready var press_to_start = $starship_and_camera/camera/UI_control/press_to_start_button

func _physics_process(delta):
	if not awaiting_start:
		distance = maxf(0, distance - (speed * delta))
	var starship_offset = remap(distance, 0, 200, 110, 200)
	starship_and_camera.position.x = -starship_offset
	distance_progress.set_value(distance)
	
	if distance <= 0.0:
		finish_minigame(false)
	pass

func initialize(weirdness_index: float = 0.0, _hull_stress_wormhole: int = 10):
	distance = MAX_DISTANCE #resetting distance
	
	press_to_start.show()
	awaiting_start = true
	
	const hardest_assumed_speed = 30.0
	const hardest_assumed_upper = 20
	const hardest_assumed_lower = 10
	
	speed = maxf(10.0, hardest_assumed_speed * weirdness_index)
	var upper_average = hardest_assumed_upper * remap(weirdness_index, 0.0, 1.0, 3.0, 1.0)
	upper_boundry = global_data.get_randf(upper_average * 0.75, upper_average * 1.25)
	var lower_average = hardest_assumed_lower * weirdness_index 
	lower_boundry = maxf(0.0, global_data.get_randf(lower_average * 0.75, lower_average * 1.25))
	
	distance_upper.value = upper_boundry
	distance_lower.value = lower_boundry
	
	hull_stress_wormhole = _hull_stress_wormhole
	pass

func _on_brake_button_button_up():
	if (distance <= upper_boundry) and (distance >= lower_boundry):
		finish_minigame(true)
	else:
		finish_minigame(false)
	pass

func finish_minigame(result: bool) -> void:
	match result:
		true:
			emit_signal("addPlayerHullStress", hull_stress_wormhole)
		false:
			emit_signal("addPlayerHullStress", hull_stress_wormhole * 2)
	
	emit_signal("finishWormholeMinigame")
	get_tree().paused = false
	pass

func _on_press_to_start_button_pressed():
	press_to_start.hide()
	awaiting_start = false
	pass 
