extends Control

var system: starSystemAPI
var locked_body_identifier: int

var point_count: int = 20
var radius: int = 50
var points: Dictionary = {}

func _physics_process(delta):
	points.clear()
	for i in point_count:
		var theta = (360 / point_count - 1) * i
		var x = radius * cos(theta)
		var y = radius * sin(theta)
		var new_point_pos = Vector2(x + get_screen_centre().x, y + get_screen_centre().y)
		points[new_point_pos] = 1.0
	
	if locked_body_identifier:
		for body in system.bodies:
			if body.is_planet() or body.is_star():
				var locked_body = system.get_body_from_identifier(locked_body_identifier)
				var dir = locked_body.position.direction_to(body.position)
				var dist = locked_body.position.distance_to(body.position)
				var mass = body.metadata.get("mass")
				
				var magnitude: float = (dist * mass)
				var closest_point = get_closest_point_to_direction(dir)
				
				points[closest_point] = 1.0 + magnitude
	
	
	queue_redraw()
	pass

func get_closest_point_to_direction(dir: Vector2):
	var distance_dict: Dictionary = {}
	for point in points:
		distance_dict[point] = point.distance_to(dir * radius)
	distance_dict.values().sort()
	var closest_point = distance_dict.find_key(distance_dict.values().front())
	return closest_point

func _draw():
	for point in points:
		draw_circle(point, points.get(point), Color.RED)
	pass

func get_screen_centre():
	return (get_viewport_rect().size / 2)
