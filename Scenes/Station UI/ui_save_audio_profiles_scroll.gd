extends VBoxContainer

var display_warning: bool = true
@onready var warning = $WARNING
@onready var observed_bodies_list = $observed_bodies_list

func _on_upgrade_state_change(upgrade_idx: playerAPI.UPGRADE_ID, state: bool):
	if upgrade_idx == playerAPI.UPGRADE_ID.AUDIO_VISUALIZER:
		display_warning = !state
		match display_warning:
			true:
				warning.show()
				observed_bodies_list.hide()
			false:
				warning.hide()
				observed_bodies_list.show()
	
	print_debug("DISPLAY WARNING: ", !display_warning)
	pass
