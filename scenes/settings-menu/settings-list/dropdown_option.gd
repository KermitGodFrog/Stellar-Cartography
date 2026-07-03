extends "res://scenes/settings-menu/settings-list/option.gd"

@onready var title = $scroll/title
@onready var dropdown = $scroll/dropdown

func reset_display_to_applied() -> void: #reset to current applied settings
	match wID:
		"WINDOW_MODE":
			dropdown.select(dropdown.get_item_index(DisplayServer.window_get_mode()))
		"FPS_LIMIT":
			var max_fps = Engine.get_max_fps()
			match max_fps:
				0:
					dropdown.select(0)
				_:
					for idx in dropdown.item_count: #item count starts at 0
						var text = dropdown.get_item_text(idx) as String
						if text.is_valid_int():
							if text.to_int() == max_fps:
								dropdown.select(idx)
	pass

func reset_display_to_default() -> void: #reset to default settings
	match wID:
		"WINDOW_MODE":
			dropdown.select(0)
		"FPS_LIMIT":
			dropdown.select(0)
	pass



func _on_dropdown_item_selected(_index: int) -> void:
	emit_signal("changed", get_wID())
	pass
