extends Camera2D
var zoom_multiplier: Vector2 = Vector2.ONE
var movement_multiplier: int = 100
var follow_body: bodyAPI

var mouse_slide_fixed_point: Vector2 = Vector2(0,0)

var previous_move_vector: Vector2 = Vector2.ZERO
func _physics_process(delta):
	if follow_body: position = follow_body.position
	
	var zoom_axis = Input.get_axis("SC_SYSTEM_MAP_ZOOM_OUT", "SC_SYSTEM_MAP_ZOOM_IN")
	if zoom_axis and not (zoom_axis == -1 and zoom == Vector2.ONE):
		zoom += zoom_axis * zoom_multiplier * (zoom.length() / 100)
	
	var input = Input.get_vector("SC_SYSTEM_MAP_LEFT", "SC_SYSTEM_MAP_RIGHT", "SC_SYSTEM_MAP_UP", "SC_SYSTEM_MAP_DOWN")
	if input:
		position += input * movement_multiplier * pow(zoom.length(), -0.5) * delta
		follow_body = null
		previous_move_vector = input
	elif previous_move_vector != Vector2.ZERO:
		previous_move_vector = Vector2.ZERO
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE, "eventsHandler", "speak", self, "system_map_camera_move")
	
	if Input.is_action_just_pressed("SC_PAN"):
		mouse_slide_fixed_point = get_viewport().get_mouse_position()
	if Input.is_action_pressed("SC_PAN"):
		var pos = get_viewport().get_mouse_position()
		global_position.x += (pos.x - mouse_slide_fixed_point.x) * pow(zoom.length(), -0.5) * delta
		global_position.y += (pos.y - mouse_slide_fixed_point.y) * pow(zoom.length(), -0.5) * delta
		follow_body = null
	pass

func _unhandled_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom += 10 * zoom_multiplier * (zoom.length() / 100)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom += -10 * zoom_multiplier * (zoom.length() / 100)
	pass
