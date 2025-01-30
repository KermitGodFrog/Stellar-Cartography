extends Control

@onready var locked_body_label = $locked_body_label

var TUTORIAL_INGRESS_OVERRIDE: bool = false
var TUTORIAL_OMISSION_OVERRIDE: bool = false

var system: starSystemAPI
var locked_body_identifier: int

var _ping_length: int = 0 #game.gd _on_sonar_values_changed
var _ping_direction: Vector2 = Vector2.ZERO
var _player_position: Vector2 = Vector2.ZERO #game.gd _physics_process

var point_count: int = 20
var radius: int = 50
var points: Dictionary = {}
var pingable_points: Dictionary = {}

func _physics_process(_delta):
	points.clear()
	pingable_points.clear()
	var locked_body = system.get_body_from_identifier(locked_body_identifier)
	for i in point_count:
		var theta = (360 / point_count - 1) * i
		var x = radius * cos(theta)
		var y = radius * sin(theta)
		var new_point_pos = Vector2(x + get_screen_centre().x, y + get_screen_centre().y)
		points[new_point_pos] = 1.0
	
	for body in system.bodies:
		if body is circularBodyAPI and body.get_identifier() != locked_body_identifier:
			if locked_body: #display isnt shown if no body is locked to base points around
				
				if body.get_display_name() == "Omission":
					if TUTORIAL_OMISSION_OVERRIDE == true:
						continue
				if body.get_display_name() == "Ingress":
					if TUTORIAL_INGRESS_OVERRIDE == true:
						continue
				
				var dir = locked_body.position.direction_to(body.position)
				var dist = locked_body.position.distance_to(body.position)
				var mass = body.mass
				
				var magnitude: float = global_data.get_randf(0,1)
				if not body.get_type() == starSystemAPI.BODY_TYPES.WORMHOLE:
					#magnitude = (dist * mass) as dist increase, magnitude increase - bad
					magnitude = minf(((mass / dist) * 100), 20.0) #20.0 is maximum magnitude
				
				var closest_point = get_closest_point_to_direction(dir)
				
				points[closest_point] += 4.0 + magnitude
				
				if _player_position.distance_to(body.position) < _ping_length:
					if _ping_direction != Vector2.ZERO:
						pingable_points[closest_point] = true
	
	if locked_body: 
		if locked_body.is_known: locked_body_label.set_text(locked_body.get_display_name())
		elif locked_body.is_theorised_but_not_known(): locked_body_label.set_text("Unknown")
	else: locked_body_label.set_text("")
	queue_redraw()
	pass

func get_closest_point_to_direction(dir: Vector2):
	var distance_dict: Dictionary = {}
	for point in points:
		distance_dict[point] = point.distance_to((dir * radius) + get_screen_centre())
	var sorted_values = distance_dict.values().duplicate()
	sorted_values.sort()
	var closest_point = distance_dict.find_key(sorted_values.front())
	return closest_point

func _draw():
	for point in points:
		draw_line(point, (point + get_screen_centre().direction_to(point) * (radius / 2)), Color.DARK_OLIVE_GREEN, 10.0)
		if pingable_points.get(point, false) == true:
			draw_circle(point, points.get(point), Color.RED)
		else:
			draw_circle(point, points.get(point), Color.DARK_RED)
	pass

func get_screen_centre():
	return (get_viewport_rect().size / 2)
