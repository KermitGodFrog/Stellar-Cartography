extends Resource
class_name objectiveAPI

enum STATES {INACTIVE, ACTIVE, SUCCESS, FAILURE}
@export_storage var current_state: STATES = STATES.INACTIVE

@export var title: String = String()
@export_multiline var description = String()

@export var categories: Array[String] = [] #game checks for all objectives in a category and bulk performs actions on em when asked to
@export var sub_objectives: Array[objectiveAPI] = [] #
