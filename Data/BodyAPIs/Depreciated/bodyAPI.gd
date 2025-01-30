extends Resource
class_name oldBodyAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

@export var identifier: int
@export var display_name: String

@export var hook_identifier: int #identifier

@export var distance: float #in solar radii
@export var orbit_speed: float
@export var radius: float
@export var metadata: Dictionary = {}

@export var position: Vector2
@export var rotation: float #radians

@export var pings_to_be_theorised: int = 3
@export var is_theorised: bool = false
@export var is_known: bool = false

enum VARIATIONS {LOW, MEDIUM, HIGH}
@export var current_variation: int = -1
@export var guessed_variation: int = -1

func get_identifier():
	return identifier

func set_identifier(new_identifier: int):
	identifier = new_identifier
	pass

func get_display_name():
	return display_name

func set_display_name(new_display_name: String):
	display_name = new_display_name
	pass

func get_current_variation():
	return current_variation

func get_guessed_variation():
	return guessed_variation

func set_current_variation(new_variation: VARIATIONS):
	current_variation = new_variation
	pass

func is_star() -> bool:
	if metadata.has("luminosity"):
		return true
	else:
		return false

func is_planet() -> bool:
	if not metadata.has("luminosity") and metadata.has("planet_classification"):
		return true
	else:
		return false

func is_asteroid_belt() -> bool:
	if metadata.has("asteroid_belt_classification"):
		return true
	else:
		return false

func is_wormhole() -> bool:
	return false #cant be wormhole because script does not extend bodyAPI

func is_anomaly() -> bool:
	return false

func is_entity() -> bool:
	return false

func is_station() -> bool:
	return false

func is_rendezvous_point() -> bool:
	if metadata.has("rendezvous_point_seed"):
		return true
	else:
		return false

func is_theorised_but_not_known() -> bool:
	if is_theorised and is_known:
		return false
	elif is_theorised and (not is_known):
		return true
	elif (not is_theorised) and is_known:
		return false #??????????????????
	else:
		return false

func is_valid_for_system_list() -> bool:
	if (is_star() or is_planet() or is_wormhole() or is_station() or is_anomaly() or is_entity() or is_rendezvous_point()):
		return true
	else:
		return false

func is_planet_with_valid_PA() -> bool:
	if is_planet():
		if ((metadata.get("has_planetary_anomaly", false) == true) and (metadata.get("is_planetary_anomaly_available", false) == true)):
			return true
	return false

func is_anomaly_with_valid_SA() -> bool:
	if is_anomaly():
		if (metadata.get("is_space_anomaly_available", true) == true):
			return true
	return false
