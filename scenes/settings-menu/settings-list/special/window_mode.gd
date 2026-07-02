extends "res://scenes/settings-menu/settings-list/dropdown_option.gd"

func get_current_id() -> int:
	return DisplayServer.window_get_mode()
