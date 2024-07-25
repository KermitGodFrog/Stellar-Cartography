extends Node2D
#updates a map and object list based on data it is fed by the game component. updates camera position for some reason

signal updatePlayerTargetPosition(pos: Vector2)
signal updateTargetPosition(pos: Vector2)
signal updatedLockedBody(body: bodyAPI)
signal lockedBodyDepreciated

signal system3DPopup
signal sonarPopup
signal barycenterPopup
signal audioVisualizerPopup

signal DEBUG_REVEAL_ALL_WORMHOLES
signal DEBUG_REVEAL_ALL_BODIES

var system: starSystemAPI
var player_position_matrix: Array = [Vector2(0,0), Vector2(0,0)]

#this atrocity is the result of godots terrible system for detecting if the mouse is above a UI element
#should change to:  get_viewport().gui_get_focus_owner()
var mouse_over_system_list: bool = false
var mouse_over_actions_panel: bool = false
var mouse_over_go_to_button: bool = false
var mouse_over_orbit_button: bool = false
var mouse_over_stop_button: bool = false
var mouse_over_tabs: bool = false
var mouse_over_ui: bool = false

var has_focus: bool = false

@onready var camera = $camera
@onready var movement_lock_timer = $movement_lock_timer
@onready var system_list = $camera/canvas/control/tabs/OVERVIEW/system_list
@onready var follow_body_label = $camera/canvas/control/tabs/INFO/follow_body_label
@onready var body_attributes_list = $camera/canvas/control/tabs/INFO/body_attributes_list
@onready var orbit_button = $camera/canvas/control/tabs/OVERVIEW/actions_panel/actions_scroll/orbit_button
@onready var go_to_button = $camera/canvas/control/tabs/OVERVIEW/actions_panel/actions_scroll/go_to_button
@onready var picker_label = $camera/canvas/control/tabs/INFO/picker_panel/picker_margin/picker_scroll/picker_label
@onready var picker_button = $camera/canvas/control/tabs/INFO/picker_panel/picker_margin/picker_scroll/picker_button
@onready var console = $camera/canvas/control/console

var camera_target_position: Vector2 = Vector2.ZERO
var follow_body : bodyAPI
var locked_body : bodyAPI
var action_body : bodyAPI
enum ACTION_TYPES {NONE, GO_TO, ORBIT}
var current_action_type

var rotation_hint: float #used for orbiting mechanics
var orbit_line_opacity_hint: float = 0.0
var body_size_multiplier_hint: float = 0.0

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
	if mouse_over_system_list or mouse_over_actions_panel or mouse_over_go_to_button or mouse_over_orbit_button or mouse_over_stop_button or mouse_over_tabs: mouse_over_ui = true
	else: mouse_over_ui = false
	
	#moving to the mouse position or moving to action_body in various ways
	if Input.is_action_pressed("right_mouse") and has_focus and (not mouse_over_ui) and movement_lock_timer.is_stopped():
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
	if Input.is_action_pressed("left_mouse") and has_focus and (not mouse_over_ui) and movement_lock_timer.is_stopped():
		camera_target_position = get_global_mouse_position()
		emit_signal("updateTargetPosition", get_global_mouse_position())
		emit_signal("lockedBodyDepreciated")
	
	if Input.is_action_just_pressed("the B") and has_focus: #DEBUG!!!!!!!!!!!!!!!!!
		emit_signal("DEBUG_REVEAL_ALL_WORMHOLES")
	
	if Input.is_action_just_pressed("the N") and has_focus: #DEBUG!!!!!!!!!!!!!!!!!
		emit_signal("DEBUG_REVEAL_ALL_BODIES")
	
	#incredibly out of plcace!!!!!
	if camera.follow_body:
		camera_target_position = Vector2.ZERO
	#SETTING CAMERA FOCUS
	camera.system_has_focus = has_focus
	
	#disabling certain movement buttons when no locked body
	if not locked_body:
		orbit_button.set("disabled", true)
		go_to_button.set("disabled", true)
	else:
		orbit_button.set("disabled", false)
		go_to_button.set("disabled", false)
	
	#setting system list and drawing screen
	system_list.clear()
	var camera_position_to_bodies: Dictionary = {}
	for body in system.bodies:
		camera_position_to_bodies[body.get_identifier()] = body.position.distance_to(camera.position)
	var sorted_values = camera_position_to_bodies.values()
	sorted_values.sort()
	var closest_body_id = camera_position_to_bodies.find_key(sorted_values.front())
	
	var star = system.get_first_star()
	var star_item_idx = system_list.add_item(str(star.display_name + " - ", star.metadata.get("star_type"), " Class Star"))
	system_list.set_item_metadata(star_item_idx, star.get_identifier())
	
	for body in system.bodies:
		if body.is_theorised_but_not_known(): if (body.is_planet() or body.is_wormhole() or body.is_station()):
			var new_item_idx: int
			new_item_idx = system_list.add_item("> ???")
			system_list.set_item_metadata(new_item_idx, body.get_identifier())
			if body == follow_body:
				system_list.set_item_custom_bg_color(new_item_idx, Color.LIGHT_SKY_BLUE)
			
		if body.is_known: if (body.is_planet() or body.is_wormhole() or body.is_station()):
			var new_item_idx: int
			if body.is_planet(): new_item_idx = system_list.add_item(str("> ", body.display_name + " - ", body.metadata.get("planet_type"), " Planet"))
			if body.is_wormhole(): new_item_idx = system_list.add_item(str("> ", body.display_name + " - ", "Wormhole"))
			if body.is_station(): new_item_idx = system_list.add_item(str("> ", body.display_name + " - ", "Station"))
			
			system_list.set_item_metadata(new_item_idx, body.get_identifier())
			
			if body.get_identifier() == closest_body_id:
				system_list.set_item_custom_bg_color(new_item_idx, Color.WEB_GRAY)
			else:
				system_list.set_item_custom_bg_color(new_item_idx, Color.DARK_SLATE_GRAY)
			
			if body == follow_body:
				system_list.set_item_custom_bg_color(new_item_idx, Color.LIGHT_SKY_BLUE)
			
			if body.is_wormhole(): if body.is_disabled:
				system_list.set_item_custom_bg_color(new_item_idx, Color.DARK_RED)
			
	
	#updating sonar ping visualization time values & sonar polygon display time
	SONAR_POLYGON_DISPLAY_TIME = maxi(0, SONAR_POLYGON_DISPLAY_TIME - delta)
	if SONAR_PINGS:
		for ping in SONAR_PINGS:
			ping.updateTime(delta)
			if ping.time == 0:
				SONAR_PINGS.erase(ping)
	
	#INFOR TAB!!!!!!! \/\/\\/\/
	if follow_body and follow_body.is_known: follow_body_label.set_text(str(">>> ", follow_body.get_display_name()))
	elif follow_body and follow_body.is_theorised_but_not_known(): follow_body_label.set_text(">>> Unknown")
	else: follow_body_label.set_text(">>> LOCK BODY FOR INFO")
	body_attributes_list.clear()
	if follow_body: 
		#global
		body_attributes_list.add_item(str("Radius : ", follow_body.radius * 109.1, " (Earth radii)"), null, false)
		body_attributes_list.add_item(str("Orbital Speed : ", follow_body.orbit_speed), null, false)
		body_attributes_list.add_item(str("Orbital Distance : ", follow_body.distance, " (Solar Radii)"), null, false)
		#metadata
		var excluding = ["iterations", "color", "value"]
		if follow_body.is_known:
			for entry in follow_body.metadata:
				if excluding.find(entry) == -1:
					var parse: String
					match entry:
						"mass": parse = str(follow_body.metadata.get(entry) * 333000, " (Earth masses)")
						_: parse = str(follow_body.metadata.get(entry))
					body_attributes_list.add_item(str(entry, " : ", parse), null, false)
	
	#PICKER UTILITY \/\/\/\/\/
	if follow_body: if follow_body.is_planet() and follow_body.get_current_variation() != null:
		var data_for_planet_type = system.planet_type_data.get(follow_body.metadata.get("planet_type"))
		var variation_class = data_for_planet_type.get("variation_class")
		if variation_class != null and (follow_body.is_known == true):
			picker_label.show()
			picker_button.show()
			picker_label.set_text(str(variation_class.to_upper().replace("_", " "), " (AUDIO VISUALIZER): "))
			if follow_body.get_guessed_variation() != null:
				picker_button.select(follow_body.get_guessed_variation())
			else: picker_button.select(-1)
		else:
			picker_label.hide()
			picker_button.hide()
	else:
		picker_label.hide()
		picker_button.hide()
	
	queue_redraw()
	pass

func _draw():
	draw_map()
	draw_sonar()
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
		if belt.is_known: draw_arc(belt.position, belt.radius, -10, TAU, 50, belt.metadata.get("color"), belt.metadata.get("width"), false)
	
	for body in system.bodies:
		if not (body.is_asteroid_belt() or body.is_station()) and body.is_known:
			if camera.zoom.length() < system.get_first_star().radius * 100.0:
				orbit_line_opacity_hint = lerp(orbit_line_opacity_hint, 0.2, 0.05)
				body_size_multiplier_hint = lerp(body_size_multiplier_hint, pow(camera.zoom.length(), -0.5) * 2.5, 0.05)
				if system.get_body_from_identifier(body.hook_identifier):
					draw_arc(system.get_body_from_identifier(body.hook_identifier).position, body.distance, -TAU, TAU, 30, Color(0.23529411764705882, 0.43137254901960786, 0.44313725490196076, orbit_line_opacity_hint), 1.0, false)
				draw_circle(body.position, body_size_multiplier_hint, body.metadata.get("color"))
			else:
				orbit_line_opacity_hint = lerp(orbit_line_opacity_hint, 0.0, 0.05)
				body_size_multiplier_hint = lerp(body_size_multiplier_hint, body.radius, 0.05)
				draw_circle(body.position, body_size_multiplier_hint, body.metadata.get("color"))
	for body in system.get_stations(): #TEMP!!!!!
		draw_circle(body.position, body.radius, Color.NAVAJO_WHITE)
	
	var size_exponent = pow(camera.zoom.length(), -0.5)
	#draw_dashed_line(camera.position, system.get_first_star().position, Color(255,255,255,100), size_exponent, 1.0, false)
	draw_line(player_position_matrix[0], player_position_matrix[1], Color.ANTIQUE_WHITE, size_exponent)
	draw_circle(player_position_matrix[0], size_exponent, Color.WHITE)
	if camera_target_position != Vector2.ZERO:
		draw_circle(camera_target_position, size_exponent * 1.5, Color.LIGHT_SKY_BLUE)
		draw_line(player_position_matrix[0], player_position_matrix[0] + (player_position_matrix[0].direction_to(camera_target_position) * 100.0), Color.LIGHT_SKY_BLUE, size_exponent)
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

func _on_stop_button_pressed():
	locked_body = null
	action_body = null
	emit_signal("updatePlayerTargetPosition", player_position_matrix[0])
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
			body.pings_to_be_theorised = maxi(0, body.pings_to_be_theorised - 1)
			if body.pings_to_be_theorised == 0:
				body.is_theorised = true #so it says '???' on the overview
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

func _on_found_body(id: int):
	var body_pos = system.get_body_from_identifier(id).position
	var ping = load("res://Data/Ping Display Helpers/discovery.tres").duplicate(true)
	ping.position = body_pos
	ping.resetTime()
	SONAR_PINGS.append(ping)
	pass

func _on_start_movement_lock_timer():
	if movement_lock_timer.is_stopped():
		movement_lock_timer.start()
		locked_body = null
		action_body = null
	pass

func _on_picker_button_item_selected(index):
	if follow_body:
		follow_body.guessed_variation = index
	pass

func _on_add_console_item(text: String, bg_color: Color = Color.WHITE, time: int = 500):
	console.async_add_item(text, bg_color, time)
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

func _on_stop_button_mouse_entered():
	mouse_over_stop_button = true
	pass

func _on_stop_button_mouse_exited():
	mouse_over_stop_button = false
	pass

func _on_tabs_mouse_entered():
	mouse_over_tabs = true
	pass 

func _on_tabs_mouse_exited():
	mouse_over_tabs = false
	pass



func _on_scopes_button_pressed():
	emit_signal("system3DPopup")
	pass 

func _on_sonar_button_pressed():
	emit_signal("sonarPopup")
	pass 

func _on_barycenter_button_pressed():
	emit_signal("barycenterPopup")
	pass 

func _on_audio_visualizer_button_pressed():
	emit_signal("audioVisualizerPopup")
	pass
