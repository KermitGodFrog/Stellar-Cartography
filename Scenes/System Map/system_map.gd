extends Node2D
#updates a map and object list based on data it is fed by the game component. updates camera position for some reason

signal updatePlayerActionType(type: playerAPI.ACTION_TYPES, action_body)
signal validUpdatePlayerActionType(type: playerAPI.ACTION_TYPES, action_body) #used for checking if the player is no longer orbiting a body in game.gd!
signal updatePlayerIsBoosting(is_boosting: bool)
signal updatePlayerTargetPosition(pos: Vector2)
signal updateTargetPosition(pos: Vector2)
signal updatedLockedBody(body: bodyAPI)
signal lockedBodyDepreciated
signal theorisedBody(id: int)

signal audioVisualizerPopup
signal journeyMapPopup
signal longRangeScopesPopup

signal removeHullStressForNanites(amount: int, nanites_per_percentage: int)

signal DEBUG_REVEAL_ALL_WORMHOLES
signal DEBUG_REVEAL_ALL_BODIES
signal DEBUG_QUICK_ADD_NANITES

var TUTORIAL_INGRESS_OVERRIDE: bool = false
var TUTORIAL_OMISSION_OVERRIDE: bool = false

var system: starSystemAPI:
	set(value):
		system = value
		clear_system_list_caches()
var player_position_matrix: Array = [Vector2(0,0), Vector2(0,0)]
var _player_status_matrix: Array = [0,0,0,0]
var player_is_boosting: bool = false
var player_audio_visualizer_unlocked: bool = false

@onready var camera = $camera
@onready var system_list = $camera/canvas/control/tabs/OVERVIEW/system_list
@onready var follow_body_label = $camera/canvas/control/tabs/INFO/follow_body_label
@onready var body_attributes_list = $camera/canvas/control/tabs/INFO/body_attributes_list
@onready var orbit_button = $camera/canvas/control/tabs/OVERVIEW/actions_panel/actions_scroll/orbit_button
@onready var go_to_button = $camera/canvas/control/tabs/OVERVIEW/actions_panel/actions_scroll/go_to_button
@onready var picker_label = $camera/canvas/control/tabs/INFO/picker_panel/picker_margin/picker_scroll/picker_label
@onready var picker_button = $camera/canvas/control/tabs/INFO/picker_panel/picker_margin/picker_scroll/picker_button
@onready var console = $camera/canvas/control/console
@onready var audio_visualizer_button = $camera/canvas/control/scopes_snap_scroll/core_and_value_scroll/core_panel_bg/core_panel_scroll/apps_panel/apps_margin/apps_scroll/audio_visualizer_button
@onready var status_scroll = $camera/canvas/control/scopes_snap_scroll/core_and_value_scroll/core_panel_bg/core_panel_scroll/status_panel/status_margin/status_scroll
@onready var map_overlay = $camera/canvas/map_overlay
@onready var data_value_increase_label = $camera/canvas/control/scopes_snap_scroll/core_and_value_scroll/data_value_increase_label
@onready var scan_prediction_upgrade = $scan_prediction_upgrade

@onready var LIDAR_ping = preload("res://Sound/SFX/LIDAR_ping.tres")
@onready var LIDAR_bounceback = preload("res://Sound/SFX/LIDAR_bounceback.tres")
@onready var LIDAR_discovery = preload("res://Sound/SFX/LIDAR_discovery.tres")
@onready var LIDAR_anomaly_discovery = preload("res://Sound/SFX/LIDAR_anomaly_discovery.tres")
@onready var boost_start_wav = preload("res://Sound/SFX/boost_start.wav")
@onready var boost_end_wav = preload("res://Sound/SFX/boost_end.wav")
enum BOOST_SOUND_TYPES {START, END}

@onready var question_mark_icon = preload("res://Graphics/question_mark.png")
@onready var entity_icon = preload("res://Graphics/entity_32x.png")
@onready var audio_visualizer_icon = preload("res://Graphics/audio_visualizer_frame.png")
@onready var station_frame = load("res://Graphics/station_frame.png")

var camera_target_position: Vector2 = Vector2.ZERO
var follow_body : bodyAPI
var locked_body : bodyAPI
var action_body : bodyAPI

var orbit_line_opacity_hint: float = 0.0
var body_size_multiplier_hint: float = 0.0

#to dispaly data from sonar interface
var SONAR_PINGS: Array[pingDisplayHelperAPI]
var SONAR_POLYGON: PackedVector2Array
var SONAR_POLYGON_DISPLAY_TIME: float = 0

#system list
var collapsed_cache: Dictionary = {}
var selected_cache: Dictionary = {} #CURRENTLY DOES NOTHING BECAUSE I CANT FIGURE OUT HOW TO MAKE IT WORK!
var closest_body_id: int

func _ready():
	status_scroll.connect("removeHullStressForNanites", _on_remove_hull_stress_for_nanites)
	pass

func _physics_process(delta):
	status_scroll.player_status_matrix = _player_status_matrix
	scan_prediction_upgrade._player_position_matrix = player_position_matrix
	scan_prediction_upgrade._SONAR_POLYGON_DISPLAY_TIME = SONAR_POLYGON_DISPLAY_TIME
	#If body clicked on in system list, follow the body with the camera (follow body).
	#If body clicked on in system list, actions can itneract with the body (locked body).
	#If actions pressed, perform on locked body (action body).
	#If body selected in system list changes, keep the previous action body.
	#Follow body is replicated to camera.
	#If camera moves, follow body is removed for camera.
	
	#camera_target_position is position for system3d to look at
	#incredibly out of plcace!!!!!
	if camera.follow_body:
		camera_target_position = Vector2.ZERO
	
	#disabling certain movement buttons when no locked body
	if not locked_body:
		orbit_button.set("disabled", true)
		go_to_button.set("disabled", true)
	else:
		orbit_button.set("disabled", false)
		go_to_button.set("disabled", false)
	
	var camera_position_to_bodies: Dictionary = {}
	for body in system.bodies:
		camera_position_to_bodies[body.get_identifier()] = body.position.distance_to(camera.position)
	var sorted_values = camera_position_to_bodies.values()
	sorted_values.sort()
	closest_body_id = camera_position_to_bodies.find_key(sorted_values.front()) #FOR SYSTEM LIST, create_item_for_body()
	
	generate_system_list()
	
	#updating sonar ping visualization time values & sonar polygon display time
	SONAR_POLYGON_DISPLAY_TIME = maxi(0, SONAR_POLYGON_DISPLAY_TIME - delta)
	if SONAR_PINGS:
		for ping in SONAR_PINGS:
			ping.updateTime(delta)
			if ping.time == 0:
				SONAR_PINGS.erase(ping)
	
	#INFOR TAB!!!!!!! \/\/\\/\/
	if follow_body and follow_body.is_known: follow_body_label.set_text(str(">>> ", follow_body.get_display_name().capitalize()))
	elif follow_body and follow_body.is_theorised_but_not_known(): follow_body_label.set_text(">>> Unknown")
	else: follow_body_label.set_text(">>> LOCK BODY FOR INFO")
	body_attributes_list.clear()
	if follow_body: 
		#global
		body_attributes_list.add_item("radius : %.2f (earth radii)" % (follow_body.radius * 109.1), null, false)
		body_attributes_list.add_item("orbital_speed : %.2f (rot/frame)" % follow_body.orbit_speed, null, false)
		body_attributes_list.add_item("orbital_distance %.2f (solar radii)" % follow_body.distance, null, false)
		#metadata
		var excluding = ["iterations", "color", "value", "has_planetary_anomaly", "is_planetary_anomaly_available", "is_anomaly_available", "planetary_anomaly_seed", "has_missing_AO"]
		if follow_body.is_known:
			for entry in follow_body.metadata:
				if excluding.find(entry) == -1:
					var parse: String
					match entry:
						"mass": parse = "%.2f (earth masses)" % (follow_body.metadata.get(entry) * 333000)
						"luminosity": parse = "%.2f" % (follow_body.metadata.get(entry))
						_: parse = str(follow_body.metadata.get(entry))
					body_attributes_list.add_item("%s : %s" % [entry, parse], null, false)
	
	#PICKER UTILITY \/\/\/\/\/
	if follow_body: if follow_body.is_planet() and follow_body.get_current_variation() != -1:
		var data_for_planet_type = system.planet_type_data.get(follow_body.metadata.get("planet_type"))
		var variation_class = data_for_planet_type.get("variation_class")
		if variation_class != null and (follow_body.is_known == true) and (follow_body.metadata.get("has_missing_AO", false) == true):
			picker_label.show()
			picker_button.show()
			picker_label.set_text(str(variation_class.to_upper().replace("_", " "), " (AUDIO VISUALIZER): "))
			if follow_body.get_guessed_variation() != -1:
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



func generate_system_list() -> void:
	system_list.clear()
	recursive_add(system.get_first_star(), null) #RECUSION IS SO COOL
	pass

func recursive_add(body: bodyAPI, parent: TreeItem) -> void:
	if body != null:
		var new = create_item_for_body(body, parent)
		for b in system.get_bodies_with_hook_identifier(body.get_identifier()):
			recursive_add(b, new)
	pass

func create_item_for_body(body: bodyAPI, parent: TreeItem) -> TreeItem:
	if body.is_valid_for_system_list():
		var item: TreeItem = system_list.create_item(parent)
		item.set_metadata(0, body.get_identifier())
		
		if body.is_theorised_but_not_known():
			item.set_text(0, "???")
			
			if body.get_identifier() == closest_body_id: 
				item.set_custom_bg_color(0, Color.DARK_SLATE_GRAY.lightened(0.2)) #WEB_GRAY
			else:
				item.set_custom_bg_color(0, Color.DARK_SLATE_GRAY)
			
			if body == follow_body:
				item.set_custom_bg_color(0, Color.DARK_SLATE_GRAY.lightened(0.5)) #LIGHT_SKY_BLUE
		
		elif body.is_known:
			if body.is_star(): item.set_text(0, "%s - %s Class Star" % [body.display_name, body.metadata.get("star_type")])
			if body.is_planet(): item.set_text(0, "%s - %s Planet" % [body.get_display_name(), body.metadata.get("planet_type")])
			if body.is_wormhole(): item.set_text(0, "%s - Wormhole" % body.get_display_name())
			if body.is_station(): item.set_text(0, "%s - Station" % body.get_display_name())
			if body.is_anomaly(): item.set_text(0, "%s" % body.get_display_name())
			if body.is_entity(): item.set_text(0, "%s" % game_data.ENTITY_CLASSIFICATIONS.find_key(body.entity_classification).capitalize())
			
			#earlier entries override later entries
			
			if body.get_identifier() == closest_body_id: 
				item.set_custom_bg_color(0, Color.DARK_SLATE_GRAY.lightened(0.2)) #WEB_GRAY
			else:
				item.set_custom_bg_color(0, Color.DARK_SLATE_GRAY)
			
			if body.is_star(): if body.get_identifier() == closest_body_id:
				item.set_custom_bg_color(0, Color(0.18, 0.18, 0.18, 0.416).lightened(0.2))
			else:
				item.set_custom_bg_color(0, Color(0.18, 0.18, 0.18, 0.416))
			
			if body == follow_body:
				item.set_custom_bg_color(0, Color.DARK_SLATE_GRAY.lightened(0.5)) #LIGHT_SKY_BLUE
			
			if body.is_wormhole():
				item.set_custom_bg_color(0, Color.WEB_PURPLE)
			
			if body.is_wormhole(): if body.get_identifier() == closest_body_id:
				item.set_custom_bg_color(0, Color.WEB_PURPLE.lightened(0.2))
			
			if body.is_wormhole(): if body == follow_body:
				item.set_custom_bg_color(0, Color.WEB_PURPLE.lightened(0.5))
			
			if body.is_wormhole(): if body.is_disabled: 
				item.set_custom_bg_color(0, Color.DARK_RED)
			
			if body.is_wormhole(): if body.is_disabled: if body.get_identifier() == closest_body_id:
				item.set_custom_bg_color(0, Color.DARK_RED.lightened(0.2))
			
			if body.is_wormhole(): if body.is_disabled: if body == follow_body: 
				item.set_custom_bg_color(0, Color.DARK_RED.lightened(0.5))
			
			if body.is_station():
				item.set_icon(0, station_frame)
			
			if body.is_entity():
				item.set_icon(0, get_entity_frame(body.entity_classification))
			
			if body.is_planet(): if (body.metadata.get("has_missing_AO", false) == true) and (body.get_guessed_variation() == -1) and (player_audio_visualizer_unlocked == true):
				item.set_icon(0, audio_visualizer_icon)
			
			if body.is_planet(): if (body.metadata.get("has_planetary_anomaly", false) == true) and (body.metadata.get("is_planetary_anomaly_available", false) == true):
				item.set_icon(0, question_mark_icon)
			
			if body.is_anomaly(): if body.metadata.get("is_space_anomaly_available", true) == true:
				item.set_icon(0, question_mark_icon)
		
		var c = collapsed_cache.get(body.get_identifier())
		if c != null:
			item.set_collapsed(c)
		
		return item
	return null

func clear_system_list_caches() -> void:
	print("SYSTEM MAP (DEBUG): CLEARING SYSTEM LIST CACHES")
	collapsed_cache.clear()
	pass



func _unhandled_input(event):
	if event.is_action_pressed("SC_INTERACT2_RIGHT_MOUSE"):
		var closest_body = game_data.get_closest_body(system.bodies, get_global_mouse_position())
		if get_global_mouse_position().distance_to(closest_body.position) < (1 + pow(camera.zoom.length(), -0.5)) and closest_body.is_known:
			emit_signal("updatedLockedBody", closest_body)
			locked_body = closest_body
			follow_body = closest_body
			camera.follow_body = closest_body
			action_body = closest_body
			emit_signal("updatePlayerActionType", playerAPI.ACTION_TYPES.ORBIT, action_body)
			return
		
		locked_body = null
		action_body = null
		emit_signal("updatePlayerTargetPosition", get_global_mouse_position())
		emit_signal("updatePlayerActionType", playerAPI.ACTION_TYPES.NONE, null)
	
	if event.is_action_pressed("SC_INTERACT1_LEFT_MOUSE"):
		var closest_body = game_data.get_closest_body(system.bodies, get_global_mouse_position())
		if get_global_mouse_position().distance_to(closest_body.position) < (1 + pow(camera.zoom.length(), -0.5)) and closest_body.is_known:
			emit_signal("updatedLockedBody", closest_body)
			locked_body = closest_body
			follow_body = closest_body
			camera.follow_body = closest_body
			return
		
		camera_target_position = get_global_mouse_position()
		emit_signal("updateTargetPosition", get_global_mouse_position())
		emit_signal("lockedBodyDepreciated")
	
	if event.is_action_pressed("SC_DEBUG_REVEAL_ALL_WORMHOLES"): #DEBUG!!!!!!!!!!!!!!!!!
		emit_signal("DEBUG_REVEAL_ALL_WORMHOLES")
	
	if event.is_action_pressed("SC_DEBUG_REVEAL_ALL_BODIES"): #DEBUG!!!!!!!!!!!!!!!!!
		emit_signal("DEBUG_REVEAL_ALL_BODIES")
	
	if event.is_action_pressed("SC_DEBUG_QUICK_ADD_NANITES"):
		emit_signal("DEBUG_QUICK_ADD_NANITES")
	
	if event.is_action_pressed("SC_BOOST"):
		player_is_boosting = true
		emit_signal("updatePlayerIsBoosting", player_is_boosting)
		async_play_boost_sound(BOOST_SOUND_TYPES.START)
	elif event.is_action_released("SC_BOOST"):
		player_is_boosting = false
		emit_signal("updatePlayerIsBoosting", player_is_boosting)
		async_play_boost_sound(BOOST_SOUND_TYPES.END)
	pass

func reset_player_boosting() -> void:
	player_is_boosting = false
	emit_signal("updatePlayerIsBoosting", player_is_boosting)
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
	
	var size_exponent = pow(camera.zoom.length(), -0.5)
	
	if camera.zoom.length() < system.get_first_star().radius * 100.0: map_overlay.show()
	else: map_overlay.hide()
	
	for body in system.bodies:
		
		#batch orbit line drawing:
		
		if not (body.is_star() or body.is_asteroid_belt() or body.is_station() or body.is_anomaly() or body.is_entity()) and body.is_known:
			if camera.zoom.length() < system.get_first_star().radius * 100.0:
				orbit_line_opacity_hint = lerp(orbit_line_opacity_hint, 0.2, 0.05)
				if system.get_body_from_identifier(body.hook_identifier):
					draw_arc(system.get_body_from_identifier(body.hook_identifier).position, body.distance, -TAU, TAU, 30, Color(0.23529411764705882, 0.43137254901960786, 0.44313725490196076, orbit_line_opacity_hint), 1.0, false)
					#draw_custom_arc(system.get_body_from_identifier(body.hook_identifier).position, body.distance, -360, 360, Color(0.23529411764705882, 0.43137254901960786, 0.44313725490196076, orbit_line_opacity_hint))
	
	for body in system.bodies:
		
		#batching circle drawing:
		
		if not (body.is_asteroid_belt() or body.is_station() or body.is_anomaly() or body.is_entity()) and body.is_known:
			if camera.zoom.length() < system.get_first_star().radius * 100.0:
				body_size_multiplier_hint = lerp(body_size_multiplier_hint, pow(camera.zoom.length(), -0.5) * 2.5, 0.05)
				
				if body == follow_body:
					draw_circle(body.position, body_size_multiplier_hint * 1.75, body.metadata.get("color").lerp(Color(1.0, 1.0, 1.0, 0.0), 0.50))
					draw_circle(body.position, body_size_multiplier_hint, body.metadata.get("color"))
				elif body.get_identifier() == closest_body_id:
					draw_circle(body.position, body_size_multiplier_hint * 1.5, body.metadata.get("color").lerp(Color(1.0, 1.0, 1.0, 0.0), 0.75))
					draw_circle(body.position, body_size_multiplier_hint, body.metadata.get("color"))
				else:
					draw_circle(body.position, body_size_multiplier_hint, body.metadata.get("color"))
				
			else:
				body_size_multiplier_hint = lerp(body_size_multiplier_hint, body.radius, 0.05)
				draw_circle(body.position, body_size_multiplier_hint, body.metadata.get("color"))
		
		if (body.is_station() or body.is_anomaly() or body.is_entity()) and body.is_known:
			if not camera.zoom.length() < system.get_first_star().radius * 100.0:
				draw_circle(body.position, body.radius, Color.NAVAJO_WHITE)
	
	for body in system.bodies:
		
		#batching entity icons:
		
		if (body.is_station() or body.is_anomaly() or body.is_entity()) and body.is_known:
			if camera.zoom.length() < system.get_first_star().radius * 100.0:
				entity_icon.draw_rect(get_canvas_item(), Rect2(body.position.x - (size_exponent * 2.5 / 2), body.position.y - (size_exponent * 2.5 / 2), size_exponent * 2.5, size_exponent * 2.5), false)
	
	for body in system.bodies:
		
		#batching anomaly map icons:
		
		if body.is_planet(): if ((body.metadata.get("has_planetary_anomaly", false) == true) and (body.metadata.get("is_planetary_anomaly_available", false) == true)) and body.is_known:
			if camera.zoom.length() < system.get_first_star().radius * 100.0:
				question_mark_icon.draw_rect(get_canvas_item(), Rect2(body.position.x + (size_exponent * 5.0 / 2), body.position.y + (size_exponent * 5.0 / 2), size_exponent * 5.0, size_exponent * 5.0), false)
		elif body.is_anomaly(): if (body.metadata.get("is_space_anomaly_available", true) == true) and body.is_known:
			if camera.zoom.length() < system.get_first_star().radius * 100.0:
				question_mark_icon.draw_rect(get_canvas_item(), Rect2(body.position.x + (size_exponent * 5.0 / 2), body.position.y + (size_exponent * 5.0 / 2), size_exponent * 5.0, size_exponent * 5.0), false)
	
	#draw_dashed_line(camera.position, system.get_first_star().position, Color(255,255,255,100), size_exponent, 1.0, false)
	draw_line(player_position_matrix[0], player_position_matrix[1], Color.ANTIQUE_WHITE, size_exponent)
	#player_icon.draw_rect(get_canvas_item(), Rect2(player_position_matrix[0].x - (size_exponent * 3.0 / 2), player_position_matrix[0].y - (size_exponent * 3.0 / 2), size_exponent * 3.0, size_exponent * 3.0), false, Color(1,1,1,1), false)
	draw_rect(Rect2(player_position_matrix[0].x - (size_exponent * 3.0 / 2), player_position_matrix[0].y - (size_exponent * 3.0 / 2), size_exponent * 3.0, size_exponent * 3.0), Color.WHITE, true)
	
	#draw_circle(player_position_matrix[0], size_exponent, Color.WHITE)
	if camera_target_position != Vector2.ZERO:
		draw_circle(camera_target_position, size_exponent * 1.5, Color.LIGHT_SKY_BLUE)
		draw_line(player_position_matrix[0], player_position_matrix[0] + (player_position_matrix[0].direction_to(camera_target_position) * 100.0), Color.LIGHT_SKY_BLUE, size_exponent)
	#draw_texture_rect(camera_here_tex, Rect2(Vector2(camera_target_position.x - size_exponent, camera_target_position.y - size_exponent), Vector2(size_exponent,size_exponent)), false)
	pass

func draw_custom_arc(center, radius, angle_from, angle_to, color): #this is used under the assumption that batching can only occur on polygons/lines/rects, although this info is from godot 3.5 so idk (NO THICKNESS VARIABBLE, NOT SURE HOW TO ADD, ABANDONED THIS)
	var nb_points = 32
	var points_arc = PackedVector2Array()
	for i in range(nb_points + 1):
		var angle_point = deg_to_rad(angle_from + i * (angle_to-angle_from) / nb_points - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	for index_point in range(nb_points):
		draw_line(points_arc[index_point], points_arc[index_point + 1], color)
	pass



func _on_go_to_button_pressed():
	if locked_body:
		action_body = locked_body
		emit_signal("updatePlayerActionType", playerAPI.ACTION_TYPES.GO_TO, action_body)
	pass

func _on_orbit_button_pressed():
	#not sure who will have jurisdiction
	if locked_body:
		action_body = locked_body
		emit_signal("updatePlayerActionType", playerAPI.ACTION_TYPES.ORBIT, action_body)
	pass

func _on_stop_button_pressed():
	locked_body = null
	action_body = null
	emit_signal("updatePlayerTargetPosition", player_position_matrix[0])
	emit_signal("updatePlayerActionType", playerAPI.ACTION_TYPES.NONE, null)
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
		
		if body.get_display_name() == "Ingress":
			if TUTORIAL_INGRESS_OVERRIDE == true:
				continue
		if body.get_display_name() == "Omission":
			if TUTORIAL_OMISSION_OVERRIDE == true:
				continue
		
		if Geometry2D.is_point_in_polygon(body.position, points):
			async_add_ping(body)
	
	#random pings \/\/\/\/
	#for random_ping in global_data.get_randi(0, remap(ping_width, 5, 90, 0, 10)):
		#var ping = load("res://Data/Ping Display Helpers/normal.tres").duplicate(true)
		#ping.position = global_data.random_triangle_point(a,b,c)
		#ping.resetTime()
		#SONAR_PINGS.append(ping)
	
	get_tree().call_group("audioHandler", "play_once", LIDAR_ping, 0.0, "SFX")
	pass

func async_add_ping(body: bodyAPI) -> void:
	await get_tree().create_timer((player_position_matrix[0].distance_to(body.position) / 100)).timeout
	
	body.pings_to_be_theorised = maxi(0, body.pings_to_be_theorised - 1)
	if body.pings_to_be_theorised == 0:
		if not body.is_theorised:
			emit_signal("theorisedBody", body.get_identifier())
		body.is_theorised = true #so it says '???' on the overview
	var pings = ["res://Data/Ping Display Helpers/normal.tres"]
	var ping = load(pings.pick_random()).duplicate(true)
	ping.position = body.position
	ping.resetTime()
	SONAR_PINGS.append(ping)
	
	get_tree().call_group("audioHandler", "play_once", LIDAR_bounceback, 0.0, "SFX")
	pass

func async_play_boost_sound(sound: BOOST_SOUND_TYPES):
	var instance = AudioStreamPlayer.new()
	instance.set_bus("SFX")
	instance.set_volume_db(-24)
	match sound:
		BOOST_SOUND_TYPES.START:
			instance.set_stream(boost_start_wav)
		BOOST_SOUND_TYPES.END:
			instance.set_stream(boost_end_wav)
	add_child(instance)
	instance.play()
	await instance.finished
	instance.queue_free()
	pass

func _on_sonar_values_changed(ping_width: int, ping_length: int, ping_direction: Vector2): #for SCAN_PREDICTION upgrade!
	scan_prediction_upgrade._on_sonar_values_changed(ping_width, ping_length, ping_direction)
	pass




func _on_remove_hull_stress_for_nanites(amount: int, nanites_per_percentage: int) -> void:
	emit_signal("removeHullStressForNanites", amount, nanites_per_percentage)
	pass

func get_entity_frame(classification: game_data.ENTITY_CLASSIFICATIONS) -> Resource:
	match classification:
		game_data.ENTITY_CLASSIFICATIONS.SPACE_WHALE_POD: return load("res://Graphics/space_whale_pod_frame.png")
		game_data.ENTITY_CLASSIFICATIONS.LAGRANGE_CLOUD: return load("res://Graphics/lagrange_cloud_frame.png")
		
		_: return load("res://Graphics/empty_frame.png")

func _on_found_body(id: int):
	var body = system.get_body_from_identifier(id)
	var body_pos = body.position
	var ping = load("res://Data/Ping Display Helpers/discovery.tres").duplicate(true)
	ping.position = body_pos
	ping.resetTime()
	SONAR_PINGS.append(ping)
	
	if body.is_planet_with_valid_PA() or body.is_anomaly_with_valid_SA():
		get_tree().call_group("audioHandler", "play_once", LIDAR_anomaly_discovery, 0.0, "SFX")
	else:
		get_tree().call_group("audioHandler", "play_once", LIDAR_discovery, 0.0, "SFX")
	pass

func _on_picker_button_item_selected(index):
	if follow_body:
		follow_body.guessed_variation = index
	pass

func _on_add_console_entry(text: String, text_color: Color = Color.WHITE):
	console.add_entry(text, text_color)
	pass

func _on_clear_console_entries():
	console.clear_entries()
	pass

func _on_player_data_value_changed(new_value: int):
	data_value_increase_label.set_text("%.fn" % new_value)
	if new_value != 0:
		data_value_increase_label.blink()
	pass



func _on_audio_visualizer_button_pressed():
	emit_signal("audioVisualizerPopup")
	pass

func _on_journey_map_button_pressed():
	emit_signal("journeyMapPopup")
	pass 

func _on_long_range_scopes_button_pressed():
	emit_signal("longRangeScopesPopup")
	pass



func _on_system_list_item_collapsed(item):
	collapsed_cache[item.get_metadata(0)] = item.is_collapsed()
	pass

func _on_system_list_item_selected():
	follow_and_lock_item(system_list.get_selected())
	pass 

func _on_system_list_item_mouse_selected(_position, mouse_button_index):
	if mouse_button_index == MouseButton.MOUSE_BUTTON_RIGHT:
		var item = system_list.get_item_at_position(_position)
		if item:
			follow_and_lock_item(item)
			_on_orbit_button_pressed()
	pass

func follow_and_lock_item(item: TreeItem):
	var identifier: int
	if item: 
		identifier = item.get_metadata(0)
	if identifier:
		var body = system.get_body_from_identifier(identifier)
		if body.is_theorised_but_not_known() or body.is_known:
			emit_signal("updatedLockedBody", body)
			locked_body = body
			follow_body = body
			camera.follow_body = follow_body
	pass

