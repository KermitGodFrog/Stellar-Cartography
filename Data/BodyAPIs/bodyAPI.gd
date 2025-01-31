extends Resource
class_name bodyAPI
#not displayed anywhere in game

@export var current_type: starSystemAPI.BODY_TYPES:
	get = get_type, set = set_type
@export var identifier: int:
	get = get_identifier, set = set_identifier
@export var display_name: String:
	get = get_display_name, set = set_display_name
@export var hook_identifier: int
##On interaction (theorised, orbiting, following), the game will set this as the value of the 'id' fact, if configured. Leave empty to let the game search for more complex queries derived from the body type.
@export var dialogue_tag: String:
	get = get_dialogue_tag, set = set_dialogue_tag
@export var metadata: Dictionary = {}

func get_type() -> starSystemAPI.BODY_TYPES:
	return current_type
func set_type(value) -> void:
	current_type = value
	pass
func get_identifier() -> int:
	return identifier
func set_identifier(value) -> void:
	identifier = value
	pass
func get_dialogue_tag() -> String:
	return dialogue_tag
func set_dialogue_tag(value) -> void:
	dialogue_tag = value
	pass
func get_display_name() -> String:
	return display_name
func set_display_name(value) -> void:
	display_name = value
	pass

@export var orbit_distance: float
@export var orbit_speed: float
@export var radius: float #this is used for important things like player exclusion zone from bodies in 3d, player orbit distance from body, etc. set to (1.0 / 192.1) as a default (earth size). 

@export_storage var position: Vector2
@export var rotation: float

@export var pings_to_be_theorised: int = 3
@export var theorised: bool = false:
	get = is_theorised
@export var known: bool = false:
	get = is_known
@export var hidden: bool = false: #hidden ON SYSTEM LIST and ON SYSTEM MAP
	get = is_hidden
func is_theorised() -> bool:
	return theorised
func is_known() -> bool:
	return known
func is_hidden() -> bool:
	return hidden
func is_theorised_not_known() -> bool:
	if (not known) and theorised:
		return true
	else:
		return false

func advance() -> void:
	pass
