extends articleAPI
class_name bodyAPI
#class for stuff that orbits on the system map. kinda static like stuff.

@export var current_type: starSystemAPI.BODY_TYPES:
	get = get_type, set = set_type
@export var hook_identifier: int

func get_type() -> starSystemAPI.BODY_TYPES:
	return current_type
func set_type(value) -> void:
	current_type = value
	pass

@export var orbit_distance: float
@export var orbit_angle_change: float #the change in rotation of a body IN RADIANS per unit of time given its orbital distance
##Used as the bodies LITERAL radius (for circularBodyAPIs), but is also used in calculations regarding player exclusion zones and player orbital distance.
@export var radius: float

@export var rotation: float

@export_storage var pings_to_be_theorised: int = 3
@export_storage var theorised: bool = false:
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
func is_not_known_or_is_hidden() -> bool:
	if (not known) or hidden:
		return true
	else:
		return false

@export var req_scope_mode: playerAPI.SCOPE_MODES = playerAPI.SCOPE_MODES.VIS
##The scope mode - 'VIS' or 'RAD' - required to discover the body (if applicable). Default is 'VIS'.
func get_required_scope_mode() -> playerAPI.SCOPE_MODES:
	return req_scope_mode
