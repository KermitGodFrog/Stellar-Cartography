extends "res://instantiated-scenes/info-popups/auto_vid_switch_popup.gd"

func set_popup_state(_state: objectiveAPI.STATES) -> void:
	match _state:
		objectiveAPI.STATES.NONE:
			show()
			
			await get_tree().create_timer(0.15, true).timeout
			
			if start_on_video:
				_on_switch_button_pressed()
			
			if flash_switch_button_until_pressed:
				switch_button_flash.oscillate_property(self, "current_color", Color.WHITE, Color.YELLOW, 20, 10, true)
		_:
			pass
	pass
