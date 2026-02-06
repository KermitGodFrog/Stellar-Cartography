extends bodyAPI
class_name unitBodyAPI
#this is a kinda hacky hack class that the game interprets differently to the normal bodyAPI inherited classes
#it doesnt orbit - it has a target position and moves towards it depending on its internal speed
#these are also drawn differently by system_map
#however they still have all of the information required to be orbiting, they just dont because doing this was easier than any other method and i need to cut corners !!! 
#im not willing to completely overhaul the starSystemAPI class to have these as separate things to bodyAPIs. yes unnecessary data; yes its still ok its cool i think :)))) rlly cool thx for being understanding !!! :))))

@export var speed: int
func get_adjusted_speed() -> int:
	if boosting:
		return speed * 5 * (1 + (-int(in_asteroid_belt) * 0.5))
	else:
		return speed * (1 + (-int(in_asteroid_belt) * 0.5))

var boosting: bool = false
var in_asteroid_belt: bool = false
var in_pulsar_beam: bool = false

@export_storage var target_position: Vector2 = Vector2.ZERO

func updatePosition(delta) -> void:
	if not position.distance_to(target_position) < get_adjusted_speed():
		position += position.direction_to(target_position) * get_adjusted_speed() * delta
	else:
		position += position.direction_to(target_position) * position.distance_to(target_position) * delta
	pass
