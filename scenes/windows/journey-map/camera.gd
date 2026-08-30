extends Camera2D

@onready var distance_bar = $canvas/control/distance_bar
@onready var control = $canvas/control

var tracking: bool = false
var aggregrate_vertical_change: int = 0

func _process(_delta: float) -> void:
	distance_bar.set_value(abs(position.y))
	if tracking:
		control.mouse_default_cursor_shape = Control.CURSOR_DRAG
	else:
		control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pass

func _on_control_gui_input(event: InputEvent) -> void:
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
	var raw: Vector2 = position + Vector2(0,aggregrate_vertical_change)
	position = Vector2(0, clampf(raw.y, -2500.0, 0.0))
	
	tracking = false
	aggregrate_vertical_change = 0
	pass
