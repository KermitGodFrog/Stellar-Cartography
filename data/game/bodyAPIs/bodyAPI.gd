extends Resource
class_name bodyAPI

signal position_updated(new_position: Vector2) #this is called thousands of times a second (potentially). DO NOT USE OFTEN OMGGG

@export var current_type: starSystemAPI.BODY_TYPES:
	get = get_type, set = set_type
@export var identifier: int:
	get = get_identifier, set = set_identifier
@export var display_name: String:
	get = get_display_name, set = set_display_name
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
func get_display_name() -> String:
	return display_name
func set_display_name(value) -> void:
	display_name = value
	pass

##Used as the bodies LITERAL radius (for circularBodyAPIs), but is also used in calculations regarding player exclusion zones, interaction maximum distance (important for unitBodyAPIs) and player orbital distance.
@export var radius: float

@export_storage var position: Vector2:
	set(value):
		position = value
		emit_signal("position_updated", position)

@export var known: bool = false:
	get = is_known
@export var hidden: bool = false: #hidden ON SYSTEM LIST and ON SYSTEM MAP
	get = is_hidden
func is_known() -> bool:
	return known
func is_hidden() -> bool:
	return hidden
func is_not_known_or_is_hidden() -> bool:
	if (not known) or hidden:
		return true
	else:
		return false

func is_known_or_is_theorised_but_not_hidden() -> bool: #has to be in bodyAPI despite orbitBodyAPI having 'theorised' stuff so no checks for whether is orbitBodyAPI have to be performed
	if hidden:
		return false
	elif known:
		return true
	return false

func initialize() -> void:
	pass
func advance(_delta) -> void:
	pass
