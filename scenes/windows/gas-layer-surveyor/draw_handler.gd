extends Control

@onready var draw_mouse_icon = preload("uid://l8jr4r03jelq")

var draw_matrix: Array[PackedVector2Array] = []
var drawing: bool = false

var allow_update: bool = false:
	get:
		if allow_update_time == float():
			allow_update_time = MAX_ALLOW_UPDATE_TIME
			return true
		else:
			return false
var allow_update_time: float = 0.0
const MAX_ALLOW_UPDATE_TIME: float = 0.05

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			var new_line_arr = PackedVector2Array()
			new_line_arr.append(get_local_mouse_position())
			draw_matrix.append(new_line_arr)
			
			allow_update_time = MAX_ALLOW_UPDATE_TIME
			
			drawing = true
			accept_event()
		elif event.is_released():
			drawing = false
			accept_event()
	elif event is InputEventMouseMotion:
		if drawing and allow_update:
			draw_matrix.back().append(event.position)
			accept_event()
	pass

func _physics_process(delta: float) -> void:
	allow_update_time = maxf(0, allow_update_time - delta)
	queue_redraw()
	pass

func _draw() -> void:
	for line_arr in draw_matrix:
		if line_arr.size() >= 2:
			draw_polyline(line_arr, Color.RED, 2.5)
		elif line_arr.size() == 1:
			draw_circle(line_arr[0], 2.5, Color.RED)
	pass

func reset_drawing() -> void:
	draw_matrix.clear()
	pass

func _on_mouse_entered() -> void:
	Input.set_custom_mouse_cursor(draw_mouse_icon)
	pass

func _on_mouse_exited() -> void:
	Input.set_custom_mouse_cursor(null)
	pass

func _on_visibility_changed() -> void:
	Input.set_custom_mouse_cursor(null)
	pass
