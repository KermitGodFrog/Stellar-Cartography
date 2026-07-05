extends Control

@onready var locked_body_label = $locked_body_label
@onready var locked_body_texture = $locked_body_texture
var tween: Tween

var system: starSystemAPI
var locked_body_identifier: int:
	set(value):
		var new_value: bool = locked_body_identifier != value
		locked_body_identifier = value
		
		if system != null:
			locked_body = system.get_body_from_identifier(locked_body_identifier)
		else:
			locked_body = null
		
		if new_value:
			_on_locked_body_identifier_changed(value)
var locked_body: bodyAPI

var _ping_length: int = 0 #game.gd _on_sonar_values_changed
var _ping_direction: Vector2 = Vector2.ZERO
var _player_position: Vector2 = Vector2.ZERO #game.gd _physics_process

var point_count: int = 12
var radius: int = 70

var points: Dictionary = {}
var pingable_points: Dictionary = {}
var glint_points: Dictionary = {}
var pingable_glint_points: Dictionary = {}

@onready var glint_texture = preload("uid://7rpr8t50r5bs")
@onready var vignette_texture = preload("uid://bx2vfswwp02np")

var texture_alpha: float = 0.0
var limited_map_alpha: float = 0.0

func _on_refresh_timeout() -> void:
	points.clear()
	pingable_points.clear()
	glint_points.clear()
	pingable_glint_points.clear()
	
	for i in point_count:
		var rad_theta = deg_to_rad((360 / point_count) * i)
		#var theta = deg_to_rad((360 / point_count) * (i + x)) # this creates a 'dead zone' where theres no barycenter info, and it rotates around the barycenter as x increases! pretty cool
		var x = radius * cos(rad_theta)
		var y = radius * sin(rad_theta)
		var new_point_pos = Vector2(x + get_screen_centre().x, y + get_screen_centre().y)
		points[new_point_pos] = 1.0
	
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
	if locked_body: 
		if locked_body.is_known(): locked_body_label.set_text(locked_body.get_display_name())
		elif locked_body.is_theorised_not_known(): locked_body_label.set_text("Unknown") #does not need override for unitBodyAPIs as it should clear before this can run
	else: locked_body_label.set_text(String())
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
	if locked_body:
		if locked_body.is_known():
			draw_rect(global_data.get_offset_rect2(((_player_position - locked_body.position) * 16.0) + get_screen_centre(), 4, 4), Color(Color.WHITE, limited_map_alpha))
			if locked_body is circularBodyAPI:
				draw_circle(get_screen_centre(), 8, Color(locked_body.surface_color, limited_map_alpha))
			elif locked_body is glintBodyAPI:
				draw_texture_rect(glint_texture, global_data.get_offset_rect2(get_screen_centre(), 16, 16), false, Color(Color.WHITE, limited_map_alpha))
		locked_body_texture.set_modulate(Color(Color("363636"), texture_alpha))
	
	draw_texture_rect(vignette_texture, get_viewport_rect(), false)
	
	for glint_point in glint_points:
		var texture_size = glint_points.get(glint_point)
		if pingable_glint_points.get(glint_point, false) == true:
			draw_texture_rect(glint_texture, global_data.get_offset_rect2(glint_point, texture_size, texture_size), false, Color.RED.darkened(0.25))
		else:
			draw_texture_rect(glint_texture, global_data.get_offset_rect2(glint_point, texture_size, texture_size), false, Color.DARK_RED.darkened(0.25))
	
	for point in points:
		var weight = points.get(point)
		if weight == 1.0:
			draw_circle(point, weight, Color("353535"))
		elif pingable_points.get(point, false) == true:
			draw_circle(point, weight, Color.RED)
		else:
			draw_circle(point, weight, Color.DARK_RED)
		
		var end = point + (point.direction_to(get_screen_centre()) * 10.0)
		draw_line(get_screen_centre() + (get_screen_centre().direction_to(end) * 40.0), end, Color("353535"), 5)
		draw_line(end, end + Vector2(0, 10).rotated(get_screen_centre().angle_to_point(end) + deg_to_rad(45)), Color("353535"), 5)
		draw_line(end, end + Vector2(0, -10).rotated(get_screen_centre().angle_to_point(end) - deg_to_rad(45)), Color("353535"), 5)
		
	pass

func get_screen_centre():
	return (get_viewport_rect().size / 2)

func _on_locked_body_identifier_changed(_new_identifier: int) -> void:
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	texture_alpha = 1.0
	limited_map_alpha = 0.0
	tween.tween_property(self, "texture_alpha", 0.0, 1.0).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "limited_map_alpha", 1.0, 0.25)
	
	if locked_body:
		if locked_body.is_known():
			var icon = game_data.get_body_icon_or_null(locked_body)
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
