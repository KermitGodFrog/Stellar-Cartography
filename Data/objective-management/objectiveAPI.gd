extends Resource
class_name objectiveAPI

@export_storage var written_identifier: String = String(): #AUTO GENERATED FROM FILE NAME, DO NOT TOUCH
	get = get_wID, set = set_wID

enum STATES {NONE, SUCCESS, FAILURE}
@export_storage var current_state: STATES = STATES.NONE:
	get = get_state, set = set_state

@export var title: String = String()
@export_multiline var description = String()

func get_state() -> STATES:
	return current_state
func set_state(value) -> void:
	current_state = value
	pass

func get_wID() -> String:
	return written_identifier
func set_wID(value) -> void:
	written_identifier = value
	pass
