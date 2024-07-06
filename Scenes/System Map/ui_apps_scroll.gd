extends VBoxContainer

var display_warning: bool = true

func _on_upgrade_state_change(upgrade_idx: playerAPI.UPGRADE_ID, state: bool):
	if upgrade_idx == playerAPI.UPGRADE_ID.AUDIO_VISUALIZER:
		$audio_visualizer_button.set_visible(state)
	pass
