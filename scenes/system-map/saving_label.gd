extends Label

var tween: Tween

func _on_world_saved() -> void:
	if tween:
		tween.kill()
	set_text(String())
	show()
	tween = create_tween()
	tween.tween_property(self, "text", "SAVING...", 0.5)
	tween.tween_interval(1.0)
	tween.tween_property(self, "text", String(), 0.25)
	tween.tween_property(self, "visible", false, 0.0)
	pass
