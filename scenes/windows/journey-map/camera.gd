extends Camera2D

var tracking: bool = false
var aggregrate_vertical_change: int = 0

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				position += Vector2(0, (-event.factor * 13))
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				position += Vector2(0, (event.factor * 13))
	
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
	position += Vector2(0,aggregrate_vertical_change)
	
	tracking = false
	aggregrate_vertical_change = 0
	pass
