extends customBodyAPI
class_name riftDriverBodyAPI

@export var driver_line: String = "RL"
@export_storage var name_locked: bool = false

func advance(_delta):
	if (metadata.get("custom_available", true) == false) and not name_locked:
		set_display_name("Rift Driver %s-%02d" % [driver_line, global_data.get_randi(0, 99)])
		name_locked = true
	pass
