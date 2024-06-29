extends Node2D
#updates a map and object list based on data it is fed by the game component. updates camera position for some reason

signal updatePlayerTargetPosition(pos: Vector2)
signal updateTargetPosition(pos: Vector2)
signal updatedLockedBody(body: bodyAPI)

signal DEBUG_REVEAL_ALL_WORMHOLES
signal DEBUG_REVEAL_ALL_BODIES

var system: starSystemAPI
var player_position_matrix: Array = [Vector2(0,0), Vector2(0,0)]

#this atrocity is the result of godots terrible system for detecting if the mouse is above a UI element
var mouse_over_system_list: bool = false
var mouse_over_actions_panel: bool = false
var mouse_over_go_to_button: bool = false
var mouse_over_orbit_button: bool = false
var mouse_over_ui: bool = false

var font = preload("res://Graphics/Fonts/comicsans.ttf")
@onready var system_list = $camera/canvas/control/tabs/OVERVIEW/system_list
@onready var follow_body_label = $camera/canvas/control/tabs/INFO/follow_body_label
@onready var body_attributes_list = $camera/canvas/control/tabs/INFO/body_attributes_list
@onready var camera = $camera
@onready var movement_lock_timer = $movement_lock_timer

var camera_target_position: Vector2 = Vector2.ZERO
var follow_body : bodyAPI
var locked_body : bodyAPI
var action_body : bodyAPI
enum ACTION_TYPES {NONE, GO_TO, ORBIT}
var current_action_type

var rotation_hint: float #used for orbiting mechanics

#to dispaly data from sonar interface
var SONAR_PINGS: Array[pingDisplayHelperAPI]
var SONAR_POLYGON: PackedVector2Array
var SONAR_POLYGON_DISPLAY_TIME: float = 0

func _physics_process(delta):
	rotation_hint += delta
	#If body clicked on in system list, follow the body with the camera (follow body).
	#If body clicked on in system list, actions can itneract with the body (locked body).
	#If actions pressed, perform on locked body (action body).
	#If body selected in system list changes, keep the previous action body.
	#Follow body is replicated to camera.
	#If camera moves, follow body is removed for camera.
	
	#camera_target_position is position for system3d to look at
	
	#checking whether the mouse is over UI
	if mouse_over_system_list or mouse_over_actions_panel or mouse_over_go_to_button or mouse_over_orbit_button: mouse_over_ui = true
	else: mouse_over_ui = false
	
	#moving to the mouse position or moving to action_body in various ways
	if Input.is_action_pressed("right_mouse") and owner.has_focus() and (not mouse_over_ui) and movement_lock_timer.is_stopped():
		locked_body = null
		action_body = null
		emit_signal("updatePlayerTargetPosition", get_global_mouse_position())
	elif action_body:
		match current_action_type:
			ACTION_TYPES.NONE:
				pass
			ACTION_TYPES.GO_TO:
				emit_signal("updatePlayerTargetPosition", action_body.position, false)
			ACTION_TYPES.ORBIT:
				var dir = Vector2.UP.rotated(rotation_hint)
				var pos = action_body.position
				pos = pos + (dir * ((3 * action_body.radius) + 1.0))
				emit_signal("updatePlayerTargetPosition", pos, false)
	
	#changing target position
	if Input.is_action_pressed("left_mouse") and owner.has_focus() and (not mouse_over_ui) and movement_lock_timer.is_stopped():
		camera_target_position = get_global_mouse_position()
		emit_signal("updateTargetPosition", get_global_mouse_position())
	
	if Input.is_action_just_pressed("the B") and owner.has_focus(): #DEBUG!!!!!!!!!!!!!!!!!
		emit_signal("DEBUG_REVEAL_ALL_WORMHOLES")
	
	if Input.is_action_just_pressed("the N") and owner.has_focus(): #DEBUG!!!!!!!!!!!!!!!!!
		emit_signal("DEBUG_REVEAL_ALL_BODIES")
	
	#incredibly out of plcace!!!!!
	if camera.follow_body:
		camera_target_position = Vector2.ZERO
	
	#setting system list and drawing screen
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
		if body.is_known: if (body.is_planet() or body.is_wormhole() or body.is_station()):
			var new_item_idx: int
			if body.is_planet(): new_item_idx = system_list.add_item(str("> ", body.display_name + " - ", body.metadata.get("planet_type"), " Planet"))
			if body.is_wormhole(): new_item_idx = system_list.add_item(str("> ", body.display_name + " - ", "Wormhole"))
			if body.is_station(): new_item_idx = system_list.add_item(str("> ", body.display_name + " - ", body.stringify_station_classification(), " Outpost"))
			
			system_list.set_item_metadata(new_item_idx, body.get_identifier())
			
			if body.get_identifier() == closest_body_id:
				system_list.set_item_custom_bg_color(new_item_idx, Color.WEB_GRAY)
			else:
				system_list.set_item_custom_bg_color(new_item_idx, Color.DARK_SLATE_GRAY)
	
	#updating sonar ping visualization time values & sonar polygon display time
	SONAR_POLYGON_DISPLAY_TIME = maxi(0, SONAR_POLYGON_DISPLAY_TIME - delta)
	if SONAR_PINGS:
		for ping in SONAR_PINGS:
			ping.updateTime(delta)
			if ping.time == 0:
				SONAR_PINGS.erase(ping)
	
	#INFOR TAB!!!!!!! \/\/\\/\/
	if follow_body: follow_body_label.set_text(str(">>> ", follow_body.get_display_name()))
	else: follow_body_label.set_text(">>> LOCK BODY FOR INFO")
	body_attributes_list.clear()
	if follow_body: for entry in follow_body.metadata:
		body_attributes_list.add_item(str(entry, " : ", follow_body.metadata.get(entry)), null, false) # must be restricted, maybe compile an exclude list somewhere
	
	
	queue_redraw()
	pass

func _draw():
	draw_sonar()
	draw_map()
	pass

func draw_sonar():
	if SONAR_POLYGON_DISPLAY_TIME != 0 and SONAR_POLYGON:
		draw_colored_polygon(SONAR_POLYGON, Color.DARK_GRAY)
	for ping in SONAR_PINGS:
		ping.updateDisplay()
		draw_circle(ping.position, ping.current_radius, ping.current_color)
	pass

func draw_map():
	var asteroid_belts = system.get_bodies_with_metadata_key("asteroid_belt_classification") #not EXACTLY proper but yknow
	if asteroid_belts: for belt in asteroid_belts:
		if belt.is_known: draw_arc(belt.position, belt.radius, -TAU, TAU, 50, belt.metadata.get("color"), belt.metadata.get("width"), false)
	for body in system.bodies:
		if not (body.is_asteroid_belt() or body.is_station()) and body.is_known:
			if camera.zoom.length() < system.get_first_star().radius * 100.0:
				if system.get_body_from_identifier(body.hook_identifier):
					draw_arc(system.get_body_from_identifier(body.hook_identifier).position, body.distance, -TAU, TAU, 30, Color(0, 0, 25, 0.2), 0.2, false)
				draw_circle(body.position, pow(camera.zoom.length(), -0.5) * 2.5, body.metadata.get("color"))
			else: draw_circle(body.position, body.radius, body.metadata.get("color"))
	for body in system.get_stations(): #TEMP!!!!!
		draw_circle(body.position, body.radius, Color.NAVAJO_WHITE)
	
	var size_exponent = pow(camera.zoom.length(), -0.5)
	#draw_dashed_line(camera.position, system.get_first_star().position, Color(255,255,255,100), size_exponent, 1.0, false)
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
		locked_body = body
		follow_body = body
		camera.follow_body = follow_body
	pass

func _on_go_to_button_pressed():
	current_action_type = ACTION_TYPES.GO_TO
	if locked_body:
		action_body = locked_body
	pass

func _on_orbit_button_pressed():
	#not sure who will have jurisdiction
	current_action_type = ACTION_TYPES.ORBIT
	if locked_body:
		action_body = locked_body
	pass

func _on_sonar_ping(ping_width: int, ping_length: int, ping_direction: Vector2):
	ping_length = remap(ping_width, 5, 90, 300, 100)
	var line = player_position_matrix[0] + ping_direction * ping_length
	
	var a = player_position_matrix[0]
	var b = line + Vector2(0,ping_width).rotated(player_position_matrix[0].angle_to_point(line))
	var c = line + Vector2(0,-ping_width).rotated(player_position_matrix[0].angle_to_point(line))
	var points: PackedVector2Array = [a,b,c]
	
	SONAR_POLYGON = points
	SONAR_POLYGON_DISPLAY_TIME = 50
	
	for body in system.bodies:
		if Geometry2D.is_point_in_polygon(body.position, points):
			var ping = load("res://Data/Ping Display Helpers/normal.tres").duplicate(true)
			ping.position = body.position
			ping.resetTime()
			SONAR_PINGS.append(ping)
	
	#random pings \/\/\/\/
	#for random_ping in global_data.get_randi(0, remap(ping_width, 5, 90, 0, 10)):
		#var ping = load("res://Data/Ping Display Helpers/normal.tres").duplicate(true)
		#ping.position = global_data.random_triangle_point(a,b,c)
		#ping.resetTime()
		#SONAR_PINGS.append(ping)
	pass

func _on_start_movement_lock_timer():
	if movement_lock_timer.is_stopped():
		movement_lock_timer.start()
		locked_body = null
		action_body = null
	pass

 



func _on_system_window_close_requested():
	owner.hide()
	pass

func _on_system_list_mouse_entered():
	mouse_over_system_list = true
	pass

func _on_system_list_mouse_exited():
	mouse_over_system_list = false
	pass

func _on_actions_panel_mouse_entered():
	mouse_over_actions_panel = true
	pass

func _on_actions_panel_mouse_exited():
	mouse_over_actions_panel = false
	pass

func _on_go_to_button_mouse_entered():
	mouse_over_go_to_button = true
	pass

func _on_go_to_button_mouse_exited():
	mouse_over_go_to_button = false
	pass

func _on_orbit_button_mouse_entered():
	mouse_over_orbit_button = true
	pass

func _on_orbit_button_mouse_exited():
	mouse_over_orbit_button = false
	pass
