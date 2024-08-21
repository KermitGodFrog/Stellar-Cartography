extends Control

var tracking: bool = false
var aggregrate_vertical_change: int = 0
signal targetFOVChange(fov: float)


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not tracking:
				tracking = true
				var timer = get_tree().create_timer(0.25)
				timer.connect("timeout", stop_tracking)
	if event is InputEventMouseMotion:
		if tracking:
			aggregrate_vertical_change += event.relative.y
	pass

func stop_tracking():
	if abs(aggregrate_vertical_change) > 50:
		if aggregrate_vertical_change > 500: aggregrate_vertical_change = 500
		if aggregrate_vertical_change < -500: aggregrate_vertical_change = -500
		
		var remap: float = remap(aggregrate_vertical_change, -500, 500, 10, 75)
		print_debug(remap)
		emit_signal("targetFOVChange", remap)
		
		tracking = false
		aggregrate_vertical_change = 0
	pass
