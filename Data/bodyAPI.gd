extends Resource
class_name bodyAPI

var identifier: int
var display_name: String

var hook_identifier: int #identifier

var distance: float #in solar radii
var orbit_speed: float
var radius: float
var metadata: Dictionary = {}

var position: Vector2
var rotation: float #radians

var pings_to_be_theorised: int = 3
var is_theorised: bool = false
var is_known: bool = false

enum VARIATIONS {LOW, MEDIUM, HIGH}
var current_variation
var guessed_variation

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

func is_star():
	if metadata.has("luminosity"):
		return true
	else:
		return false

func is_planet():
	if not metadata.has("luminosity") and metadata.has("planet_classification"):
		return true
	else:
		return false

func is_asteroid_belt():
	if metadata.has("asteroid_belt_classification"):
		return true
	else:
		return false

func is_wormhole():
	return false #cant be wormhole because script does not extend bodyAPI

func is_anomaly():
	return false

func is_station():
	return false

func is_theorised_but_not_known():
	if is_theorised and is_known:
		return false
	elif is_theorised and (not is_known):
		return true
	elif (not is_theorised) and is_known:
		return false #??????????????????
	else:
		return false
