extends Resource
class_name objectiveAPI

@export var display_name: String:
	get = get_display_name, set = set_display_name

func get_display_name() -> String:
	return display_name
func set_display_name(value) -> void:
	display_name = value
	pass
