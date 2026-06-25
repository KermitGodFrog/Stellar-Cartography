extends Control

@onready var locked_body_label = $locked_body_label
@onready var locked_body_texture = $locked_body_texture

var system: starSystemAPI
var locked_body_identifier: int:
	set(value):
		locked_body_identifier = value
		_on_locked_body_identifier_changed(value)

var _ping_length: int = 0 #game.gd _on_sonar_values_changed
var _ping_direction: Vector2 = Vector2.ZERO
var _player_position: Vector2 = Vector2.ZERO #game.gd _physics_process

var point_count: int = 20
var radius: int = 50

var points: Dictionary = {}
var pingable_points: Dictionary = {}
var glint_points: Dictionary = {}
var pingable_glint_points: Dictionary = {}

@onready var glint_texture = preload("uid://7rpr8t50r5bs")

func _on_refresh_timeout() -> void:
	points.clear()
	pingable_points.clear()
	glint_points.clear()
	pingable_glint_points.clear()
	
	for i in point_count:
		var theta = (360 / point_count - 1) * i
		var x = radius * cos(theta)
		var y = radius * sin(theta)
		var new_point_pos = Vector2(x + get_screen_centre().x, y + get_screen_centre().y)
		points[new_point_pos] = 1.0
	
	var locked_body = system.get_body_from_identifier(locked_body_identifier)
	if locked_body:
		if locked_body is not unitBodyAPI:
			generate_new_point_weights(locked_body)
	pass

func generate_new_point_weights(for_locked_body : bodyAPI) -> void:
	for body in system.bodies:
		if body is circularBodyAPI and body.get_identifier() != locked_body_identifier:
			if body.is_hidden():
				continue
			
			var dir = for_locked_body.position.direction_to(body.position)
			var dist = for_locked_body.position.distance_to(body.position)
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
		elif (body is glintBodyAPI or body is customBodyAPI) and body.get_identifier() != locked_body_identifier:
			
			if body.is_hidden():
				continue
			
			var dir = for_locked_body.position.direction_to(body.position)
			var closest_point = get_closest_point_to_direction(dir)
			glint_points[closest_point] = 10.0
			
			if _player_position.distance_to(body.position) < _ping_length:
				if _ping_direction != Vector2.ZERO:
					pingable_glint_points[closest_point] = true
	pass



func _physics_process(_delta):
	var locked_body = system.get_body_from_identifier(locked_body_identifier)
	if locked_body: 
		if locked_body.is_known(): locked_body_label.set_text(locked_body.get_display_name())
		elif locked_body.is_theorised_not_known(): locked_body_label.set_text("Unknown") #does not need override for unitBodyAPIs as it should clear before this can run
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
	for glint_point in glint_points:
		var texture_size = glint_points.get(glint_point)
		if pingable_glint_points.get(glint_point, false) == true:
			draw_texture_rect(glint_texture, global_data.get_offset_rect2(glint_point, texture_size, texture_size), false, Color.RED.darkened(0.25))
		else:
			draw_texture_rect(glint_texture, global_data.get_offset_rect2(glint_point, texture_size, texture_size), false, Color.DARK_RED.darkened(0.25))
	pass

func get_screen_centre():
	return (get_viewport_rect().size / 2)

func _on_locked_body_identifier_changed(_new_identifier: int) -> void:
	var body = system.get_body_from_identifier(_new_identifier)
	if body:
		if body.is_known():
			var icon = game_data.get_body_icon_or_null(body)
			if icon:
				locked_body_texture.set_texture(icon)
			else:
				locked_body_texture.set_texture(load("uid://ldgef1pamgcu"))
		else:
			locked_body_texture.set_texture(load("uid://ldgef1pamgcu"))
	else:
		locked_body_texture.set_texture(null)
	
	points.clear()
	pingable_points.clear()
	glint_points.clear()
	pingable_glint_points.clear()
	_on_refresh_timeout()
	pass
