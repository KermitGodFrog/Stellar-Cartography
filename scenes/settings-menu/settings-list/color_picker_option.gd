extends "res://scenes/settings-menu/settings-list/option.gd"

@onready var picker_button = $scroll/picker_button

func _ready() -> void:
	picker_button.get_picker().connect("color_changed", _on_picker_color_changed)
	super()

func reset_display_to_applied() -> void: #reset to current applied settings
	match wID:
		"DIALOGUE_BG_COLOR":
			picker_button.set_pick_color(game_data.dialogue_bg_color)
	pass

func reset_display_to_default() -> void: #reset to default settings
	match wID:
		"DIALOGUE_BG_COLOR":
			picker_button.set_pick_color(Color("3c3c3c50"))
	pass



func _on_picker_color_changed(_color: Color) -> void:
	emit_signal("changed", get_wID())
	pass
