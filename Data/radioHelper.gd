extends Resource
class_name radioHelper

signal time_over_stepped()

@export var volume_curve: Curve
@export var max_time: float = 30.0
var time: float = 0.0

func get_time() -> float:
	return time

func get_max_time() -> float:
	return max_time

func stepTime(delta: float) -> void:
	time = minf(max_time, time + delta)
	if time == max_time:
		emit_signal("time_over_stepped")
	pass

func resetTime() -> void:
	time = max_time
	pass
