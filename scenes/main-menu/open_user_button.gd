extends Button

func _on_pressed() -> void:
	OS.shell_show_in_file_manager(OS.get_user_data_dir())
	pass
