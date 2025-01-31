extends customBodyAPI

#might be able to make cooldown not @export_storage if too much data in save files
@export_storage var min_distance: float = 0.0
@export_storage var max_distance: float = 0.0
@export_storage var target_distance: float = 0.0
@export_storage var original_speed: float = 0.0
@export_storage var cooldown: float = 0.0

func initialize():
	original_speed = orbit_speed
	randomize_target_distance()
	pass

func advance(delta):
	cooldown = maxf(0.0, cooldown - delta)
	orbit_distance = move_toward(orbit_distance, target_distance, delta * 4.0)
	if (orbit_distance == target_distance) and cooldown == 0.0:
		cooldown = 10.0
		randomize_target_distance()
		randomize_speed()
	pass

func randomize_target_distance() -> void:
	target_distance = global_data.get_randf(min_distance, max_distance)
	pass

func randomize_speed() -> void:
	orbit_speed = global_data.get_randf(original_speed * 0.5, original_speed * 1.5)
	pass
