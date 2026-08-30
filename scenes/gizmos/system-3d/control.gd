extends Control

@onready var FOV_bar = $FOV_bar

var tracking: bool = false
var aggregrate_vertical_change: int = 0
var ghost_fov: float = 10.0
signal targetFOVChange(fov: float)
var min_FOV: int = 10: #playerAPI scopes_min_FOV
	set(value):
		min_FOV = value
		FOV_bar.min_value = min_FOV
var max_FOV: int = 75: #playerAPI scopes_max_FOV
	set(value):
		max_FOV = value
		FOV_bar.max_value = max_FOV

var ui_time: float = 0.0
var current_fov: float = 0.0

func _process(delta: float) -> void:
	ui_time = maxf(0.0, ui_time - delta)
	FOV_bar.modulate = Color(Color.WHITE, minf(1.0, ui_time))
	FOV_bar.set_value(current_fov)
	if tracking:
		mouse_default_cursor_shape = Control.CURSOR_DRAG
	else:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pass

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				ghost_fov = clamp(ghost_fov - (event.factor * 3), min_FOV, max_FOV)
				emit_signal("targetFOVChange", ghost_fov)
				get_viewport().set_input_as_handled()
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				ghost_fov = clamp(ghost_fov + (event.factor * 3), min_FOV, max_FOV)
				emit_signal("targetFOVChange", ghost_fov)
				get_viewport().set_input_as_handled()
	
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
		
		var remapped: float = remap(aggregrate_vertical_change, -500, 500, min_FOV, max_FOV)
		emit_signal("targetFOVChange", remapped)
	
	tracking = false
	aggregrate_vertical_change = 0
	pass



func _on_mouse_entered() -> void:
	ui_time = 2.5
	pass

func _on_target_fov_change(_fov: float) -> void:
	ui_time = 2.5
	pass 
