extends "res://scenes/system-map/custom_tooltip_button.gd"

enum DANGER_RULES {HIGH, LOW, NONE}
@export var current_danger_rule: DANGER_RULES
var value_change_tween: Tween

func _ready() -> void:
	normal()
	pass

func value_change_flash() -> void:
	if value_change_tween: value_change_tween.kill()
	value_change_tween = get_tree().create_tween().bind_node(self)
	set_modulate(Color("ffffff00"))
	value_change_tween.tween_property(self, "modulate", Color("ffffff"), 0.8).set_trans(Tween.TRANS_SINE)
	value_change_tween.play()
	pass

func update_danger(value: int) -> void:
	match current_danger_rule:
		DANGER_RULES.HIGH:
			if value >= 75:
				danger()
				return
		DANGER_RULES.LOW:
			if value <= 25:
				danger()
				return
		DANGER_RULES.NONE:
			return
	normal()
	pass

func danger() -> void:
	set("theme_override_colors/font_color", Color.RED)
	set("theme_override_colors/font_hover_color", Color.RED.darkened(0.1))
	set("theme_override_colors/font_focus_color", Color.RED)
	pass

func normal() -> void:
	set("theme_override_colors/font_color", Color.WHITE)
	set("theme_override_colors/font_hover_color", Color.LIGHT_GRAY)
	set("theme_override_colors/font_focus_color", Color.WHITE)
	pass
