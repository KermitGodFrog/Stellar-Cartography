extends "res://Scenes/System Map/custom_tooltip_button.gd"

var value_change_tween: Tween

func value_change_flash() -> void:
	if value_change_tween: value_change_tween.kill()
	value_change_tween = get_tree().create_tween().bind_node(self)
	set_modulate(Color("ffffff00"))
	value_change_tween.tween_property(self, "modulate", Color("ffffff"), 0.8).set_trans(Tween.TRANS_SINE)
	value_change_tween.play()
	pass
