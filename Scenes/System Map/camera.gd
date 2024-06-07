extends Camera2D
var zoom_multiplier: Vector2 = Vector2.ONE
var movement_multiplier: int = 100
var locked_body: bodyAPI

func _physics_process(delta):
	if locked_body: position = locked_body.position
	
	var zoom_axis = Input.get_axis("zoom_out", "zoom_in")
	if zoom_axis and not (zoom_axis == -1 and zoom == Vector2.ONE):
		if owner.has_focus(): zoom += zoom_axis * zoom_multiplier * (zoom.length() / 100)
	
	var input = Input.get_vector("left", "right", "up", "down")
	if input and owner.has_focus():
		position += input * movement_multiplier * pow(zoom.length(), -0.5) * delta
		locked_body = null
	pass
