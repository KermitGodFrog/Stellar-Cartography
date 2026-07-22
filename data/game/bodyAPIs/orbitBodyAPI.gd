extends bodyAPI
class_name orbitBodyAPI
#class for all stuff that orbits and CAN be detected using scopes!

@export var hook_identifier: int

@export var orbit_distance: float
@export var orbit_angle_change: float #the change in rotation of a body IN RADIANS per unit of time given its orbital distance

@export var rotation: float

@export_storage var pings_to_be_theorised: int = 3
@export_storage var theorised: bool = false:
	get = is_theorised
func is_theorised() -> bool:
	return theorised
func is_theorised_not_known() -> bool:
	if (not known) and theorised:
		return true
	else:
		return false


@export var req_scope_mode: playerAPI.SCOPE_MODES = playerAPI.SCOPE_MODES.VIS
##The scope mode - 'VIS' or 'RAD' - required to discover the body (if applicable). Default is 'VIS'.
func get_required_scope_mode() -> playerAPI.SCOPE_MODES:
	return req_scope_mode
