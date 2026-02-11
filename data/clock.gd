extends Resource
class_name clock

signal time_expired

@export var current_time: float
@export var max_time: float

func reset() -> void:
	current_time = max_time

func tick(delta) -> void:
	current_time = maxf(0, current_time - delta)
	if current_time == float():
		emit_signal("time_expired")

func start(time_sec: float) -> void:
	max_time = time_sec
	reset()

func is_stopped() -> bool:
	if current_time == float():
		return true
	return false
