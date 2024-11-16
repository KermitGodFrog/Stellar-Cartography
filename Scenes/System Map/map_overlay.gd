extends TextureRect

@onready var frame_update = $frame_update
var frame: int = 0


func _physics_process(delta):
	texture.region.position = Vector2(0, 112 * frame)
	pass

func _on_frame_update_timeout():
	if frame >= 11: 
		frame = 0
		return
	frame += 1
	if randf() >= 0.5:
		flip_v = !flip_v
	if randf() >= 0.5:
		flip_h = !flip_h
	pass
