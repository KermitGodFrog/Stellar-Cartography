extends Label

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		print("VISIBLE IN TREE !!!!")
		var r = global_data.convert_events_to_readable(InputMap.action_get_events("SC_QUICK_PAUSE"))
		if r.length() == 0:
			r = "[UNSET]"
		set_text("PAUSED - PRESS %s TO UNPAUSE" % r)
	pass
