extends Node3D

var speed: float = 0.0
var target_speed: float = 0.0
var distance: float = 500.0

@onready var speed_slider = $starship_and_camera/camera/UI_control/speed_slider
@onready var starship_and_camera = $starship_and_camera

func _physics_process(delta):
	speed = lerp(speed, target_speed, 0.05)
	#print(speed)
	
	var starship_offset = remap(distance, 0, 500, 110, 200)
	starship_and_camera.position.x = -starship_offset
	distance = maxi(distance - speed * delta, 0)
	pass


func initialize(weirdness_index : float = 0.0):
	pass


func _on_speed_slider_value_changed(value):
	target_speed = value
	pass
