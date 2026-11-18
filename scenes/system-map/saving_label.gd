extends Label

func _on_world_saved() -> void:
	show()
	var tween := create_tween()
	tween.tween_property(self, "text", "SAVING...", 1.0)
	tween.tween_interval(2.0)
	tween.tween_property(self, "text", String(), 0.5)
	tween.tween_property(self, "visible", false, 0.0)
	pass
