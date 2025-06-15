extends circularBodyAPI
class_name planetBodyAPI

enum VARIATIONS {LOW, MEDIUM, HIGH}
@export var current_variation: int = -1:
	get = get_current_variation, set = set_current_variation
@export_storage var guessed_variation: int = -1:
	get = get_guessed_variation, set = set_guessed_variation

func get_current_variation() -> int:
	return current_variation
func set_current_variation(value) -> void:
	current_variation = value
	pass
func get_guessed_variation() -> int:
	return guessed_variation
func set_guessed_variation(value) -> void:
	guessed_variation = value

func is_PA_valid() -> bool:
	if ((metadata.get("planetary_anomaly", false) == true) and (metadata.get("planetary_anomaly_available", false) == true)):
		return true
	return false

#Gas Layer Surveyor
@export_storage var layers: int = -1:
	get = get_gas_layers_sum, set = set_gas_layers_sum

func get_gas_layers_sum() -> int:
	return layers
func set_gas_layers_sum(value) -> void:
	layers = value
	pass
