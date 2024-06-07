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
