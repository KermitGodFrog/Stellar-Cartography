extends Resource
class_name newBodyAPI
#not displayed anywhere in game

@export var current_body_type: starSystemAPI.BODY_TYPES:
	get = get_body_type, set = set_body_type
@export var identifier: int:
	get = get_identifier, set = set_identifier
@export var display_name: String:
	get = get_display_name, set = set_display_name
@export var hook_identifier: int
@export var metadata: Dictionary = {}

func get_body_type() -> starSystemAPI.BODY_TYPES:
	return current_body_type
func set_body_type(value) -> void:
	current_body_type = value
	pass
func get_identifier() -> int:
	return identifier
func set_identifier(value) -> void:
	identifier = value
	pass
func get_display_name() -> String:
	return display_name
func set_display_name(value) -> void:
	display_name = value
	pass

@export var distance: float
@export var orbit_speed: float

@export_storage var position: Vector2
@export_storage var rotation: float

@export var pings_to_be_theorised: int = 3
@export var is_theorised: bool = false
@export var is_known: bool = false
func is_theorised_not_known() -> bool:
	if (not is_known) and is_theorised:
		return true
	else:
		return false

func advance() -> void:
	pass
