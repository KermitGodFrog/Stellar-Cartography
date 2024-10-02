extends Node2D
#updates a map and object list based on data it is fed by the game component. updates camera position for some reason

signal updatePlayerActionType(type: playerAPI.ACTION_TYPES, action_body)
signal validUpdatePlayerActionType(type: playerAPI.ACTION_TYPES, action_body) #used for checking if the player is no longer orbiting a body in game.gd!
signal updatePlayerIsBoosting(is_boosting: bool)
signal updatePlayerTargetPosition(pos: Vector2)
signal updateTargetPosition(pos: Vector2)
signal updatedLockedBody(body: bodyAPI)
signal lockedBodyDepreciated

signal audioVisualizerPopup
signal journeyMapPopup
signal longRangeScopesPopup

signal removeHullStressForNanites(amount: int, nanites_per_percentage: int)

signal DEBUG_REVEAL_ALL_WORMHOLES
signal DEBUG_REVEAL_ALL_BODIES

var system: starSystemAPI
var player_position_matrix: Array = [Vector2(0,0), Vector2(0,0)]
var player_is_boosting: bool = false

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
@onready var audio_visualizer_button = $camera/canvas/control/scopes_snap_scroll/core_panel_bg/core_panel_scroll/apps_panel/apps_margin/apps_scroll/audio_visualizer_button
@onready var hull_stress_button = $camera/canvas/control/scopes_snap_scroll/core_panel_bg/core_panel_scroll/status_panel/status_margin/status_scroll/hull_stress_button

@onready var ping_sound_scene = preload("res://Sound/ping.tscn")
@onready var bounceback_sound_scene = preload("res://Sound/bounceback.tscn")
@onready var discovery_sound_scene = preload("res://Sound/discovery.tscn")
@onready var boost_start_wav = preload("res://Sound/SFX/boost_start.wav")
@onready var boost_end_wav = preload("res://Sound/SFX/boost_end.wav")
enum BOOST_SOUND_TYPES {START, END}

@onready var question_mark_icon = preload("res://Graphics/question_mark.png")
@onready var entity_icon = preload("res://Graphics/entity_32x.png")

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

func _ready():
	hull_stress_button.connect("removeHullStressForNanites", _on_remove_hull_stress_for_nanites)
	pass

func _physics_process(delta):
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
		if body.is_theorised_but_not_known(): if (body.is_planet() or body.is_wormhole() or body.is_station() or body.is_anomaly() or body.is_entity()):
			var new_item_idx: int
			new_item_idx = system_list.add_item("> ???")
			system_list.set_item_metadata(new_item_idx, body.get_identifier())
			if body == follow_body:
				system_list.set_item_custom_bg_color(new_item_idx, Color.LIGHT_SKY_BLUE)
			
		if body.is_known: if (body.is_planet() or body.is_wormhole() or body.is_station() or body.is_anomaly() or body.is_entity()):
			var new_item_idx: int
			if body.is_planet(): new_item_idx = system_list.add_item(str("> ", body.display_name + " - ", body.metadata.get("planet_type"), " Planet"))
			if body.is_wormhole(): new_item_idx = system_list.add_item(str("> ", body.display_name + " - ", "Wormhole"))
			if body.is_station(): new_item_idx = system_list.add_item(str("> ", body.display_name + " - ", "Station"), load("res://Graphics/station_frame.png"))
			if body.is_anomaly() and body.metadata.get("is_anomaly_available", true) == true: new_item_idx = system_list.add_item("> ???")
			if body.is_entity(): new_item_idx = system_list.add_item(str("> ", game_data.ENTITY_CLASSIFICATIONS.find_key(body.entity_classification)).capitalize(), get_entity_frame(body.entity_classification))
			
			system_list.set_item_metadata(new_item_idx, body.get_identifier())
			
			if body.get_identifier() == closest_body_id:
				system_list.set_item_custom_bg_color(new_item_idx, Color.WEB_GRAY)
			else:
				system_list.set_item_custom_bg_color(new_item_idx, Color.DARK_SLATE_GRAY)
			
			if body == follow_body:
				system_list.set_item_custom_bg_color(new_item_idx, Color.LIGHT_SKY_BLUE)
			
			if body.is_wormhole(): if body.is_disabled:
				system_list.set_item_custom_bg_color(new_item_idx, Color.DARK_RED)
			
			if body.is_planet(): if (body.metadata.get("has_planetary_anomaly", false) == true) and (body.metadata.get("is_planetary_anomaly_available", false) == true):
				system_list.set_item_icon(new_item_idx, question_mark_icon)
			
			if body.is_anomaly(): if body.metadata.get("is_anomaly_available", false) == true:
				system_list.set_item_icon(new_item_idx, question_mark_icon)
	
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
		var excluding = ["iterations", "color", "value", "has_planetary_anomaly", "is_planetary_anomaly_available", "is_anomaly_available", "planetary_anomaly_seed"]
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
		if variation_class != null and (follow_body.is_known == true):
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

func _unhandled_input(event):
	if event.is_action_pressed("right_mouse") and movement_lock_timer.is_stopped():
		var closest_body = game_data.get_closest_body(system.bodies, get_global_mouse_position())
		if get_global_mouse_position().distance_to(closest_body.position) < (1 + pow(camera.zoom.length(), -0.5)) and closest_body.is_known:
			emit_signal("updatedLockedBody", closest_body)
			locked_body = closest_body
			follow_body = closest_body
			camera.follow_body = closest_body
			action_body = closest_body
			emit_signal("updatePlayerActionType", playerAPI.ACTION_TYPES.GO_TO, action_body)
			return
		
		locked_body = null
		action_body = null
		emit_signal("updatePlayerTargetPosition", get_global_mouse_position())
		emit_signal("updatePlayerActionType", playerAPI.ACTION_TYPES.NONE, null)
	
	if event.is_action_pressed("left_mouse") and movement_lock_timer.is_stopped():
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
	
	if event.is_action_pressed("the B"): #DEBUG!!!!!!!!!!!!!!!!!
		emit_signal("DEBUG_REVEAL_ALL_WORMHOLES")
	
	if event.is_action_pressed("the N"): #DEBUG!!!!!!!!!!!!!!!!!
		emit_signal("DEBUG_REVEAL_ALL_BODIES")
	
	if event.is_action_pressed("boost"):
		player_is_boosting = !player_is_boosting
		emit_signal("updatePlayerIsBoosting", player_is_boosting)
		match player_is_boosting:
			true:
				async_play_boost_sound(BOOST_SOUND_TYPES.START)
			false:
				async_play_boost_sound(BOOST_SOUND_TYPES.END)
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
	
	for body in system.bodies:
		
		if not (body.is_asteroid_belt() or body.is_station() or body.is_anomaly() or body.is_entity()) and body.is_known:
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
		
		if (body.is_station() or body.is_anomaly() or body.is_entity()) and body.is_known:
			if camera.zoom.length() < system.get_first_star().radius * 100.0:
				entity_icon.draw_rect(get_canvas_item(), Rect2(body.position.x - (size_exponent * 2.5 / 2), body.position.y - (size_exponent * 2.5 / 2), size_exponent * 2.5, size_exponent * 2.5), false, Color(1,1,1,1), false)
			else:
				draw_circle(body.position, body.radius, Color.NAVAJO_WHITE)
	
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
		if Geometry2D.is_point_in_polygon(body.position, points):
			async_add_ping(body)
	
	#random pings \/\/\/\/
	#for random_ping in global_data.get_randi(0, remap(ping_width, 5, 90, 0, 10)):
		#var ping = load("res://Data/Ping Display Helpers/normal.tres").duplicate(true)
		#ping.position = global_data.random_triangle_point(a,b,c)
		#ping.resetTime()
		#SONAR_PINGS.append(ping)
	
	var ping_instance = ping_sound_scene.instantiate()
	add_child(ping_instance)
	ping_instance.play()
	await ping_instance.finished
	ping_instance.queue_free()
	pass

func async_add_ping(body: bodyAPI) -> void:
	await get_tree().create_timer((player_position_matrix[0].distance_to(body.position) / 100)).timeout
	
	body.pings_to_be_theorised = maxi(0, body.pings_to_be_theorised - 1)
	if body.pings_to_be_theorised == 0:
		body.is_theorised = true #so it says '???' on the overview
	var ping = load("res://Data/Ping Display Helpers/normal.tres").duplicate(true)
	ping.position = body.position
	ping.resetTime()
	SONAR_PINGS.append(ping)
	
	var bounceback_instance = bounceback_sound_scene.instantiate()
	add_child(bounceback_instance)
	bounceback_instance.play()
	await bounceback_instance.finished
	bounceback_instance.queue_free()
	pass

func async_play_boost_sound(sound: BOOST_SOUND_TYPES):
	var instance = AudioStreamPlayer.new()
	instance.set_bus("SFX")
	instance.set_volume_db(-12)
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


func _on_remove_hull_stress_for_nanites(amount: int, nanites_per_percentage: int) -> void:
	emit_signal("removeHullStressForNanites", amount, nanites_per_percentage)
	pass

func get_entity_frame(classification: game_data.ENTITY_CLASSIFICATIONS) -> Resource:
	match classification:
		game_data.ENTITY_CLASSIFICATIONS.SPACE_WHALE_POD: return load("res://Graphics/space_whale_pod_frame.png")
		_: return load("res://Graphics/empty_frame.png")

func _on_found_body(id: int):
	var body_pos = system.get_body_from_identifier(id).position
	var ping = load("res://Data/Ping Display Helpers/discovery.tres").duplicate(true)
	ping.position = body_pos
	ping.resetTime()
	SONAR_PINGS.append(ping)
	
	var discovery_instance = discovery_sound_scene.instantiate()
	add_child(discovery_instance)
	discovery_instance.play()
	await discovery_instance.finished
	discovery_instance.queue_free()
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




func _on_audio_visualizer_button_pressed():
	emit_signal("audioVisualizerPopup")
	pass

func _on_journey_map_button_pressed():
	emit_signal("journeyMapPopup")
	pass 

func _on_long_range_scopes_button_pressed():
	emit_signal("longRangeScopesPopup")
	pass
