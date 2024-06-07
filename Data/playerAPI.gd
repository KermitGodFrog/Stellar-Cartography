extends Resource
class_name playerAPI

var position: Vector2 = Vector2(0,0)
var target_position: Vector2 = Vector2(0,0)
var current_star_system: starSystemAPI

var speed: int = 1

func updatePosition(delta):
	if not position.distance_to(target_position) < speed:
		position += position.direction_to(target_position) * speed * delta
	else:
		position += position.direction_to(target_position) * position.distance_to(target_position) * delta
	pass

func setTargetPosition(pos: Vector2):
	target_position = pos
	pass
