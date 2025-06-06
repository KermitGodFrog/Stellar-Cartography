extends Resource #Categories are groups of objectiveAPIs
class_name categoryAPI

@export_storage var written_identifier: String = String(): #AUTO GENERATED FROM FILE NAME, DO NOT TOUCH
	get = get_wID, set = set_wID

@export var objective_wIDs: PackedStringArray = []











func get_wID() -> String:
	return written_identifier
func set_wID(value) -> void:
	written_identifier = value
	pass
