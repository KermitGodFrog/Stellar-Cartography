extends Node

func get_closest_body(bodies, pos):
	if bodies.size() > 0:
		var distance_to_bodies: Dictionary = {}
		
		for body in bodies:
			distance_to_bodies[body] = pos.distance_to(body.position)
		distance_to_bodies.values().sort()
		return distance_to_bodies.find_key(distance_to_bodies.values()[0])
	else:
		return null

func loadWorld():
	if not FileAccess.file_exists("user://stellar_cartographer_data.save"):
		return
	
	var save_world = FileAccess.open("user://stellar_cartographer_data.save", FileAccess.READ)
	var world = save_world.get_var(true)
	return world

func saveWorld(world: worldAPI):
	var save_world = FileAccess.open("user://stellar_cartographer_data.save", FileAccess.WRITE)
	save_world.store_var(world, true)
	pass
