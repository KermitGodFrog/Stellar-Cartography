extends Label

const max_blink_time: float = 0.5
var blink_time: float = 0.0

func invalid_blink() -> void:
	blink_time = max_blink_time
	pass

func _process(delta: float) -> void:
	blink_time = maxf(0, blink_time - delta)
	
	var update_color = get("theme_override_colors/font_color")
	update_color.s = remap(blink_time, max_blink_time, 0.0, 1.0, 0.0)
	set("theme_override_colors/font_color", update_color)
	pass
