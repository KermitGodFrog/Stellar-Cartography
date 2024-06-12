extends Resource
class_name playerAPI

var position: Vector2 = Vector2(0,0)
var target_position: Vector2 = Vector2(0,0)
var current_star_system: starSystemAPI

var speed: int = 1
var balance: float = 0
var current_value: float = 0

var max_jumps: int = 5
var jumps_remaining: int = 0

func updatePosition(delta):
	if not position.distance_to(target_position) < speed:
		position += position.direction_to(target_position) * speed * delta
	else:
		position += position.direction_to(target_position) * position.distance_to(target_position) * delta
	pass

func setTargetPosition(pos: Vector2):
	target_position = pos
	pass

func resetJumpsRemaining():
	jumps_remaining = max_jumps
	pass

func removeJumpsRemaining(amount: int):
	jumps_remaining = maxi(0, jumps_remaining - amount)
	pass

func addJumpsRemaining(amount: int):
	jumps_remaining = mini(max_jumps, jumps_remaining + amount)
	pass
