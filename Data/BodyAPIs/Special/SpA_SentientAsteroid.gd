extends customBodyAPI

#might be able to make cooldown not @export_storage if too much data in save files
@export_storage var min_distance: float = 0.0
@export_storage var max_distance: float = 0.0
@export_storage var target_distance: float = 0.0
@export_storage var cooldown: float = 0.0

func initialize():
	randomize_target_distance()
	pass

func advance(delta):
	cooldown = maxf(0.0, cooldown - delta)
	orbit_distance = move_toward(orbit_distance, target_distance, delta * 4.0)
	if (orbit_distance == target_distance) and cooldown == 0.0:
		cooldown = 10.0
		randomize_target_distance()
	pass

func randomize_target_distance() -> void:
	target_distance = global_data.get_randf(min_distance, max_distance)
	pass
