extends Resource
class_name bodyAPI

@export var identifier: int
@export var display_name: String

@export var hook_identifier: int #identifier

@export var distance: float #in solar radii
@export var orbit_speed: float
@export var radius: float
@export var metadata: Dictionary = {}

var position: Vector2
var rotation: float #radians

@export var is_known: bool = false

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
