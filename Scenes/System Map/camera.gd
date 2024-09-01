extends Camera2D
var zoom_multiplier: Vector2 = Vector2.ONE
var movement_multiplier: int = 100
var follow_body: bodyAPI

func _physics_process(delta):
	if follow_body: position = follow_body.position
	
	var zoom_axis = Input.get_axis("zoom_out", "zoom_in")
	if zoom_axis and not (zoom_axis == -1 and zoom == Vector2.ONE):
		zoom += zoom_axis * zoom_multiplier * (zoom.length() / 100)
	
	var input = Input.get_vector("left", "right", "up", "down")
	if input:
		position += input * movement_multiplier * pow(zoom.length(), -0.5) * delta
		follow_body = null
	pass
