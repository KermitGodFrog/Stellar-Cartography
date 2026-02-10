extends unitBodyAPI
class_name AIUnitAPI

@export_storage var task_clock: clock = clock.new()
@export_storage var cooldown_clock: clock = clock.new()

var system: starSystemAPI: #updated in TWO ways: 1) set while creating the body, 2) updated by game.gd on _ready when in the CONTINUE query type
	get = get_system, set = set_system
var player_position_matrix: Array = [Vector2(0,0), Vector2(0,0)] #updated by game.gd _physics_process
var player_scanner_matrix: Array = [0.0, 0.0] #updated by game.gd _physics_process

func get_system() -> starSystemAPI:
	return system
func set_system(value) -> void:
	system = value
	pass

class clock extends Resource:
	
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
	
	pass
