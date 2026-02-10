extends unitBodyAPI
class_name AIUnitAPI

enum TASK_STATUSES {ONGOING, COMPLETE, FAILED}
var task_switching_enabled: bool = true

@export_storage var task_clock: clock
@export_storage var cooldown_clock: clock

@export_storage var target : orbitBodyAPI

var system: starSystemAPI: #updated in TWO ways: 1) set while creating the body, 2) updated by game.gd on _ready when in the CONTINUE query type
	get = get_system, set = set_system
var player_position_matrix: Array = [Vector2(0,0), Vector2(0,0)] #updated by game.gd _physics_process
var player_scanner_matrix: Array = [0.0, 0.0] #updated by game.gd _physics_process

func get_system() -> starSystemAPI:
	return system
func set_system(value) -> void:
	system = value
	pass



func check_task_status() -> TASK_STATUSES:
	return TASK_STATUSES.FAILED
func switch_task() -> void: #func switch_task(override: TASKS = null) -> void:
	pass
