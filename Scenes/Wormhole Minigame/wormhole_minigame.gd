extends Node3D

var speed: float = 0.0
var target_speed: float = 0.0
var distance: float = 200.0

@onready var speed_slider = $starship_and_camera/camera/UI_control/speed_slider
@onready var starship_and_camera = $starship_and_camera

@onready var speed_progress = $starship_and_camera/camera/UI_control/info_container/speed_container/speed_progress
@onready var distance_progress = $starship_and_camera/camera/UI_control/info_container/distance_container/distance_progress

func _physics_process(delta):
	speed = clampf(lerpf(speed, target_speed, 0.05), 0, 10)
	distance = maxf(0, distance - (speed * delta))
	
	var starship_offset = remap(distance, 0, 200, 110, 200)
	starship_and_camera.position.x = -starship_offset
	
	speed_progress.set_value(speed)
	distance_progress.set_value(distance)
	
	pass

func initialize(weirdness_index : float = 0.0):
	pass

func _on_speed_slider_value_changed(value):
	#print("VALUE CHANGED:!:!:!:!:! ", value)
	target_speed = value
	pass
