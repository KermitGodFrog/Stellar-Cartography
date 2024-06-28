extends TabContainer

var display_warning: bool = true

func _ready():
	set_tab_hidden(0, true)
	pass

func _on_tab_clicked(tab):
	if tab == 2:
		match display_warning:
			true: current_tab = 0
			false: current_tab = 2
	pass

func _on_upgrade_state_change(upgrade_idx: playerAPI.UPGRADE_ID, state: bool):
	if upgrade_idx == playerAPI.UPGRADE_ID.ADVANCED_SCANNING:
		display_warning = !state
		print("DISPLAY WARNING: ", !display_warning)
	pass
