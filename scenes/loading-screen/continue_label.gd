extends Label

func _ready() -> void:
	set_text("PRESS %s TO CONTINUE" % global_data.convert_events_to_readable(InputMap.action_get_events("SC_LOAD_CONFIRMATION")))
	pass
