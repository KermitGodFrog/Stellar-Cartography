extends Resource
class_name articleAPI
#shared stuff between bodyAPIs and unitAPIs !!!

signal position_updated(new_position: Vector2) #this is called thousands of times a second (potentially). DO NOT USE OFTEN OMGGG

@export var identifier: int:
	get = get_identifier, set = set_identifier
@export var display_name: String:
	get = get_display_name, set = set_display_name
@export var metadata: Dictionary = {}

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

@export_storage var position: Vector2:
	set(value):
		position = value
		emit_signal("position_updated", position)

func initialize() -> void:
	pass
func advance(_delta) -> void:
	pass
