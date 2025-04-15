extends Node
#a class designed to work with the system_map 'countdown_overlay' branch!!

signal updateCountdownOverlay(title: String, description: String, hull_stress: int)
signal countdownTick(time_current: float)
signal countdownTimeout

@onready var countdown = $countdown

var time_total: float = 0.0

func initialize(_title: String, _description: String, _hull_stress: int, _time_total: float, _time_current: float):
	time_total = _time_total
	countdown.wait_time = _time_current
	countdown.start()
	emit_signal("updateCountdownOverlay", _title, _description, _hull_stress)
	pass

func _on_countdown_timeout() -> void:
	countdown.start(time_total)
	emit_signal("countdownTimeout")
	pass


func _on_update_timeout() -> void:
	emit_signal("countdownTick", countdown.get_time_left())
	pass
