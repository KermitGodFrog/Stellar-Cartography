extends Resource
class_name objectiveAPI

@export_storage var written_identifier: String = String(): #AUTO GENERATED FROM FILE NAME, DO NOT TOUCH
	get = get_wID, set = set_wID

enum STATES {NONE, SUCCESS, FAILURE}
@export_storage var current_state: STATES = STATES.NONE:
	get = get_state, set = set_state

@export var title: String = String()
@export_multiline var description = String()

@export_storage var time: float = 0:
	get = get_time, set = set_time

func get_state() -> STATES:
	return current_state
func set_state(value) -> void:
	current_state = value
	pass

func increase_time(amount: float) -> void:
	time += amount
	pass
func set_time(amount: float) -> void:
	time = amount
func get_time() -> float:
	return time

func get_wID() -> String:
	return written_identifier
func set_wID(value) -> void:
	written_identifier = value
	pass
