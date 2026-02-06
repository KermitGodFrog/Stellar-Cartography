extends articleAPI
class_name unitAPI
#spaceships and stuff that do not orbit on the system map

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
