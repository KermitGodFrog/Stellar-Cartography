extends VBoxContainer

var display_warning: bool = true

func _on_upgrade_state_change(upgrade_idx: playerAPI.UPGRADE_ID, state: bool):
	match upgrade_idx:
		playerAPI.UPGRADE_ID.AUDIO_VISUALIZER:
			$audio_visualizer_button.set_visible(state)
		playerAPI.UPGRADE_ID.LONG_RANGE_SCOPES:
			$long_range_scopes_button.set_visible(state)
	pass
