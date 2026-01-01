extends Resource
class_name pingDisplayHelper

var position: Vector2
var current_radius: float
@export var radius_curve: Curve
var current_color: Color
@export var color_curve: Gradient

@export var max_time: float = 500.0
var time: float = 0

func resetTime():
	time = max_time

func updateTime(delta):
	time = maxi(0, time - delta)
	pass

func updateDisplay():
	var normalized_time = remap(time, 0, max_time, 1.0, 0.0)
	if radius_curve: current_radius = radius_curve.sample(normalized_time)
	if color_curve: current_color = color_curve.sample(normalized_time)
	pass

func is_expired() -> bool:
	return time == 0
