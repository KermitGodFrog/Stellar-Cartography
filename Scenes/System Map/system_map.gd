extends Node2D
#updates a map and object list based on data it is fed by the game component. updates camera position for some reason
@export var camera_here_tex = preload("res://Graphics/camera_green.png")

signal updatePlayerTargetPosition(pos: Vector2)
signal updateTargetPosition(pos: Vector2)
signal debugCreateNewStarSystem
signal updatedLockedBody(body: bodyAPI)

var system: starSystemAPI
var player_position_matrix: Array = [Vector2(0,0), Vector2(0,0)]

var mouse_over_system_list: bool = false

var font = preload("res://Graphics/Fonts/comicsans.ttf")
@onready var system_list = $camera/canvas/control/system_list
@onready var camera = $camera

#maybe shouldnt be here esc sketchy stuff
var camera_target_position: Vector2 = Vector2.ZERO

func _physics_process(delta):
	if Input.is_action_pressed("right_mouse") and not mouse_over_system_list:
		emit_signal("updatePlayerTargetPosition", get_global_mouse_position())
	
	if Input.is_action_pressed("left_mouse") and not mouse_over_system_list:
		camera_target_position = get_global_mouse_position()
		emit_signal("updateTargetPosition", get_global_mouse_position())
	
	if Input.is_action_just_pressed("action"):
		emit_signal("debugCreateNewStarSystem")
	
	#incredibly out of plcace!!!!!
	if camera.locked_body:
		camera_target_position = Vector2.ZERO
	
	system_list.clear()
	var camera_position_to_bodies: Dictionary = {}
	for body in system.bodies:
		camera_position_to_bodies[body.get_identifier()] = body.position.distance_to(camera.position)
	var sorted_values = camera_position_to_bodies.values()
	sorted_values.sort()
	var closest_body_id = camera_position_to_bodies.find_key(sorted_values.front())
	
	var star = system.get_first_star()
	system_list.add_item(str(star.display_name + " - ", star.metadata.get("star_type"), " Class Star"))
	
	for body in system.bodies:
		if body.is_known: if body.is_planet():
			var new_item_idx = system_list.add_item(str("> ", body.display_name + " - ", body.metadata.get("planet_type"), " Planet"))
			system_list.set_item_metadata(new_item_idx, body.get_identifier())
			
			if body.get_identifier() == closest_body_id:
				system_list.set_item_custom_bg_color(new_item_idx, Color.WEB_GRAY)
			else:
				system_list.set_item_custom_bg_color(new_item_idx, Color.DARK_SLATE_GRAY)
	queue_redraw()
	pass

func _draw():
	draw_map()
	pass

func draw_map():
	var asteroid_belts = system.get_bodies_with_metadata_key("asteroid_belt_classification") #not EXACTLY proper but yknow
	if asteroid_belts: for belt in asteroid_belts:
		draw_arc(belt.position, belt.radius, -10, TAU, 50, belt.metadata.get("color"), belt.metadata.get("width"), false)
	for body in system.bodies:
		if not body.is_asteroid_belt() and body.is_known:
			draw_circle(body.position, body.radius, body.metadata.get("color"))
	var size_exponent = pow(camera.zoom.length(), -0.5)
	
	draw_dashed_line(camera.position, system.get_first_star().position, Color(255,255,255,100), size_exponent, 1.0, false)
	draw_line(player_position_matrix[0], player_position_matrix[1], Color.ANTIQUE_WHITE, size_exponent)
	draw_circle(player_position_matrix[0], size_exponent, Color.WHITE)
	if camera_target_position != Vector2.ZERO:
		draw_circle(camera_target_position, size_exponent, Color.LIGHT_SKY_BLUE)
		draw_circle(camera_target_position, size_exponent * 0.8, Color.WEB_GRAY)
	#draw_texture_rect(camera_here_tex, Rect2(Vector2(camera_target_position.x - size_exponent, camera_target_position.y - size_exponent), Vector2(size_exponent,size_exponent)), false)
	pass

func _on_system_list_item_clicked(index, _at_position, _mouse_button_index):
	var index_to_identifier = system_list.get_item_metadata(index)
	if index_to_identifier:
		var body = system.get_body_from_identifier(index_to_identifier)
		emit_signal("updatedLockedBody", body)
		camera.locked_body = body
	pass
















func _on_system_list_mouse_entered():
	mouse_over_system_list = true
	pass

func _on_system_list_mouse_exited():
	mouse_over_system_list = false
	pass

func _on_system_window_close_requested():
	owner.hide()
	pass
