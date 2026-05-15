extends "res://instantiated-scenes/info-popups/info_popup.gd"

func set_popup_state(_state: objectiveAPI.STATES) -> void:
	match _state:
		objectiveAPI.STATES.NONE:
			show()
		_:
			hide()
	pass
