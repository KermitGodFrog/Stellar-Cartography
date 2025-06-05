extends Resource
class_name objectiveAPI

@export var parent: String = String() #written identifier

@export_storage var written_identifier: String = String(): #AUTO GENERATED FROM FILE NAME, DO NOT TOUCH
	get = get_wid, set = set_wid

enum STATES {INACTIVE, ACTIVE, SUCCESS, FAILURE}
@export_storage var current_state: STATES = STATES.INACTIVE:
	get = get_state, set = set_state

@export var title: String = String()
@export_multiline var description = String()

@export var categories: PackedStringArray = [] #game checks for all objectives in a category and bulk performs actions on em when asked to
@export var sub_objectives: PackedStringArray = [] #file names of sub objectives

@export var time: float = 0:
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

func get_wid() -> String:
	return written_identifier
func set_wid(value) -> void:
	written_identifier = value
	pass
