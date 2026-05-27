extends Node2D
#updates a map and object list based on data it is fed by the game component. updates camera position for some reason

var _pause_mode: game_data.PAUSE_MODES = game_data.PAUSE_MODES.NONE:
	set(value):
		_pause_mode = value
		_on_pause_mode_changed(value)
signal queuePauseMode(new_mode: game_data.PAUSE_MODES)
signal setPauseMode(new_mode: game_data.PAUSE_MODES)
func _on_pause_mode_changed(value):
	match value:
		game_data.PAUSE_MODES.NONE:
			canvas.show()
		game_data.PAUSE_MODES.DIALOGUE:
			canvas.hide()
	pass






signal updatePlayerActionType(type: playerAPI.ACTION_TYPES, action_body)
signal updatePlayerIsBoosting(is_boosting: bool)
signal updatePlayerTargetPosition(pos: Vector2)
signal updateTargetPosition(pos: Vector2)
signal updatedLockedBody(body: bodyAPI)
signal lockedBodyDepreciated
signal theorisedBody(id: int)
signal removeHullStressForNanites(amount: int, nanites_per_percentage: int)
signal playerBelowCMERingRadius
signal playerInPulsarBeamCooldownExpired
signal updatePlayerInAsteroidBelt(_player_in_asteroid_belt: bool)
signal updatePlayerInPulsarBeam(_player_in_pulsar_beam: bool)
signal toggleScopeModeSwitchButton
signal openPauseMenu
signal tutorialIngressThresholdReached
signal documentPingHitStatus(hit: bool)

signal audioVisualizerPopup
signal journeyMapPopup
signal longRangeScopesPopup
signal gasLayerSurveyorPopup

var system: starSystemAPI:
	set(value):
		system = value
		clear_system_list_caches()
var player_position_matrix: Array = [Vector2(0,0), Vector2(0,0)]
var _player_status_matrix: Array = [0,0,0,0]
var player_adj_scanner_matrix: Array = [0.0, 0.0] #this does NOT have to be updated every frame lmfao BRRRRRRRRRRRRR
var player_adj_speed: int = 0
var player_is_boosting: bool = false:
	set(value):
		if player_is_boosting != value:
			status_modifier_organizer.check_modifier("boosting", "Boosting", "(BOOSTING DESCRIPTION)", "* [color=red]+0.20 scanner profile multiplier[/color]\n* [color=green]5.0x speed[/color]", value)
		player_is_boosting = value
var player_audio_visualizer_unlocked: bool = false
var player_gas_layer_surveyor_unlocked: bool = false

@onready var camera = $camera
@onready var canvas = $camera/canvas
@onready var system_list = $camera/canvas/control/tabs_and_ca_scroll/tabs_actions_scroll/tabs/OVERVIEW/syslist_contacts_split/system_list
@onready var contact_list = $camera/canvas/control/tabs_and_ca_scroll/tabs_actions_scroll/tabs/OVERVIEW/syslist_contacts_split/contact_list
@onready var follow_body_label = $camera/canvas/control/tabs_and_ca_scroll/tabs_actions_scroll/tabs/INFO/follow_body_label
@onready var body_attributes_list = $camera/canvas/control/tabs_and_ca_scroll/tabs_actions_scroll/tabs/INFO/body_attributes_list
@onready var orbit_button = $camera/canvas/control/tabs_and_ca_scroll/tabs_actions_scroll/actions_panel/actions_scroll/orbit_button
@onready var go_to_button = $camera/canvas/control/tabs_and_ca_scroll/tabs_actions_scroll/actions_panel/actions_scroll/go_to_button
@onready var stop_button = $camera/canvas/control/tabs_and_ca_scroll/tabs_actions_scroll/actions_panel/actions_scroll/stop_button
@onready var picker_label = $camera/canvas/control/tabs_and_ca_scroll/tabs_actions_scroll/tabs/INFO/picker_panel/picker_margin/picker_scroll/picker_label
@onready var picker_button = $camera/canvas/control/tabs_and_ca_scroll/tabs_actions_scroll/tabs/INFO/picker_panel/picker_margin/picker_scroll/picker_button
@onready var console = $camera/canvas/control/console
@onready var status_control = $camera/canvas/control/scopes_snap_scroll/core_and_value_scroll/core/core_scroll/status_control
@onready var map_overlay = $camera/canvas/map_overlay
@onready var data_value_increase_label = $camera/canvas/control/scopes_snap_scroll/core_and_value_scroll/data_value_increase_label
@onready var scan_prediction_upgrade = $scan_prediction_upgrade
@onready var countdown_overlay = $camera/canvas/countdown_overlay
@onready var current_action_label = $camera/canvas/control/tabs_and_ca_scroll/arrow_and_ca_scroll/ca_panel/margin/current_action_label
@onready var status_modifier_organizer = $camera/canvas/control/scopes_snap_scroll/core_and_value_scroll/core/core_scroll/status_control/status_scroll/secondary_scroll/secondary_panel1/secondary_margin/status_modifier_organizer
@onready var view_objective_label = $camera/canvas/control/view_objectives_label
@onready var help_overlay = $camera/canvas/help_overlay
@onready var tabs = $camera/canvas/control/tabs_and_ca_scroll/tabs_actions_scroll/tabs
@onready var enable_scope_mode_switch = $enable_scope_mode_switch
@onready var info_popups = $camera/canvas/info_popups
@onready var tutorial_processor: Node
@onready var alarm_sound = $alarm_sound
@onready var proximity_blinker = $camera/canvas/control/scopes_snap_scroll/core_and_value_scroll/core/core_scroll/status_control/status_scroll/secondary_scroll/secondary_panel2/secondary_margin/bisect/proximity_blinker

@onready var LIDAR_ping = preload("uid://bk3mdgissdw10")
@onready var LIDAR_bounceback = preload("uid://l48jfwebkea")
@onready var LIDAR_discovery = preload("uid://dmdwnnnq2d2xo")
@onready var LIDAR_anomaly_discovery = preload("uid://qnadsccxvg5q")
@onready var boost_start = preload("uid://ddkrd6hh2pqhq")
@onready var boost_end = preload("uid://ir1h2au76ia5")
enum BOOST_SOUND_TYPES {START, END}

@onready var entity_texture = preload("uid://bdxkekgntbyc5")
@onready var question_mark_frame = preload("uid://gmtqybky5mo")
@onready var question_mark_texture = preload("uid://diwsd0k5wno8h")
@onready var empty_frame = preload("uid://id0yg3qh1o32")

@onready var target_texture = preload("uid://diuwq6pqf7xir")

@onready var default_font = preload("uid://xrcqj2080elm")

var camera_target_position: Vector2 = Vector2.ZERO
var follow_body_modifier : bodyAPI #used for drawing scope direction imdicator accurately and nothinh eklse
var follow_body : bodyAPI
var locked_body : bodyAPI
var action_body : bodyAPI

#to dispaly data from sonar interface
var SONAR_PINGS: Array[pingDisplayHelper]
var SONAR_POLYGON: PackedVector2Array
var SONAR_POLYGON_DISPLAY_TIME: float = 0

var MOVEMENT_PINGS: Array[pingDisplayHelper]

var TEXT_PINGS: Array[pingDisplayHelper]

#to display CME data
var CME_RING_RADIUS: int = 0
var CME_RING_SHOWN: bool = false
const CME_MAX_RING_RADIUS: int = 1000

var PULSAR_DAMAGE_COOLDOWN: float = 0.0
const PULSAR_MAX_DAMAGE_COOLDOWN: float = 1.0

#drawing scanner stuff on system map
var scanner_profile_time: float = 0.0
var scanner_power_time: float = 0.0

#system list
var collapsed_cache: Dictionary = {}
var selected_cache: Dictionary = {} #CURRENTLY DOES NOTHING BECAUSE I CANT FIGURE OUT HOW TO MAKE IT WORK!
var closest_body_id: int

#asteroid belt slowdown
var player_in_asteroid_belt: bool = false:
	set(value):
		if player_in_asteroid_belt != value:
			emit_signal("updatePlayerInAsteroidBelt", value)
			status_modifier_organizer.check_modifier("asteroid_belt", "Asteroid belt", "A loose collection of small rocks floating through the void.", "* [color=green]-0.70 scanner profile multiplier[/color]\n* [color=red]-0.75 scanner power multiplier[/color]\n* [color=red]0.5x speed[/color]", value)
		player_in_asteroid_belt = value
var player_in_pulsar_beam: bool = false: #doesnt impact speed ATM
	set(value):
		if player_in_pulsar_beam != value:
			emit_signal("updatePlayerInPulsarBeam", value)
			status_modifier_organizer.check_modifier("pulsar_beam", "Pulsar beam", "(PULSAR BEAM DESCRIPTION)", "* [color=green]-0.80 scanner profile multiplier[/color]\n* [color=red]-0.50 scanner power multiplier[/color]", value)
		player_in_pulsar_beam = value
var player_supercharged: bool = false:
	set(value):
		player_supercharged = value
		status_modifier_organizer.check_modifier("supercharged", "Supercharged", "(SUPERCHARGED DESCRIPTION)", "* [color=green]2.0x speed[/color]", value)


func _ready():
	status_control.connect("removeHullStressForNanites", _on_remove_hull_stress_for_nanites)
	status_control.connect("updateScannerDisplayTimes", _on_update_scanner_display_times)
	contact_list.create_item(null)
	pass

func _physics_process(delta):
	status_control.player_status_matrix = _player_status_matrix
	status_control.player_adj_scanner_matrix = player_adj_scanner_matrix
	status_control.player_adj_speed = player_adj_speed
	
	scan_prediction_upgrade._player_position_matrix = player_position_matrix
	scan_prediction_upgrade._SONAR_POLYGON_DISPLAY_TIME = SONAR_POLYGON_DISPLAY_TIME
	
	current_action_label._player_position_matrix = player_position_matrix
	
	if tutorial_processor != null:
		tutorial_processor._system = system
		tutorial_processor._player_position_matrix = player_position_matrix
	
	#If body clicked on in system list, follow the body with the camera (follow body).
	#If body clicked on in system list, actions can itneract with the body (locked body).
	#If actions pressed, perform on locked body (action body).
	#If body selected in system list changes, keep the previous action body.
	#Follow body is replicated to camera.
	#If camera moves, follow body is removed for camera.
	
	#camera_target_position is position for system3d to look at
	#incredibly out of plcace!!!!!
	if follow_body_modifier != null:
		camera_target_position = Vector2.ZERO
	
	#disabling certain movement buttons when no locked body
	if not locked_body:
		orbit_button.set("disabled", true)
		go_to_button.set("disabled", true)
	else:
		if locked_body is unitBodyAPI:
			orbit_button.set("disabled", true)
		else:
			orbit_button.set("disabled", false)
		go_to_button.set("disabled", false)
	
	var camera_position_to_bodies: Dictionary = {}
	for body in system.bodies:
		if body.is_not_known_or_is_hidden():
			continue
		camera_position_to_bodies[body.get_identifier()] = body.position.distance_to(camera.position)
	var sorted_values = camera_position_to_bodies.values()
	sorted_values.sort()
	closest_body_id = camera_position_to_bodies.find_key(sorted_values.front()) #FOR SYSTEM LIST, create_item_for_body()
	
	calculate_asteroid_belt_slowdown()
	calculate_pulsar_beam_slowdown_and_damage(delta)
	generate_system_list()
	update_contact_list()
	
	#updating sonar ping visualization time values & sonar polygon display time
	SONAR_POLYGON_DISPLAY_TIME = maxi(0, SONAR_POLYGON_DISPLAY_TIME - delta)
	var PING_ARRAYS = [SONAR_PINGS, MOVEMENT_PINGS, TEXT_PINGS]
	for PINGS in PING_ARRAYS:
		if PINGS:
			for ping in PINGS:
				ping.updateTime(delta)
				if ping.is_expired():
					PINGS.erase(ping)
	
	#CME shenanigans
	if CME_RING_SHOWN:
		CME_RING_RADIUS = mini(CME_MAX_RING_RADIUS, CME_RING_RADIUS + 1)
		if player_position_matrix[0].distance_to(system.get_first_star().position) < CME_RING_RADIUS:
			_on_player_below_CME_ring_radius()
		if CME_RING_RADIUS == CME_MAX_RING_RADIUS:
			CME_RING_SHOWN = false
	
	#unit update related stuff
	scanner_profile_time = maxf(0, scanner_profile_time - delta)
	scanner_power_time = maxf(0, scanner_power_time - delta)
	if get_global_mouse_position().distance_to(player_position_matrix[0]) < (1 + pow(camera.zoom.length(), -0.5)):
		_on_update_scanner_display_times(2.5, 2.5)
	for unit in system.get_units().filter(func(unit): return unit.is_known()): # not very performance motherfucker >:( but i think it makes more sense that this is here and not in update_contact_list, really. but not when CUSTOM_UNIT is added.
		if get_global_mouse_position().distance_to(unit.position) < (1 + pow(camera.zoom.length(), -0.5)):
			_on_update_scanner_display_times(2.5, 2.5)
	
	#INFOR TAB!!!!!!! \/\/\\/\/
	if follow_body and follow_body.is_known(): follow_body_label.set_text(str(">>> ", follow_body.get_display_name()))
	elif follow_body and follow_body.is_theorised_not_known(): follow_body_label.set_text(">>> Unknown") #does not need override for unitBodyAPIs as it should clear before this can run
	else: follow_body_label.set_text(">>> LOCK BODY FOR INFO")
	body_attributes_list.clear()
	if follow_body and follow_body.is_known():
		
		if follow_body is orbitBodyAPI:
			body_attributes_list.add_item("orbit_angle_change : %.2f (rad/frame)" % follow_body.orbit_angle_change, null, false)
			body_attributes_list.add_item("orbit_distance %.2f (solar radii)" % follow_body.orbit_distance, null, false)
			
			if follow_body is circularBodyAPI: 
				body_attributes_list.add_item("radius : %.2f (earth radii)" % (follow_body.radius * 109.1), null, false)
				body_attributes_list.add_item("mass : %.2f (earth masses)" % (follow_body.mass * 333000))
			
		#metadata
		var excluding = ["iterations", "color", "value", "planetary_anomaly", "planetary_anomaly_available", "space_anomaly_available", "missing_AO", "missing_GL", "seed", "custom_available", "custom_follow_available", "custom_orbit_available", "ship_available"]
		if follow_body.is_known():
			for entry in follow_body.metadata:
				if excluding.find(entry) == -1:
					var parse: String
					match entry:
						"luminosity": parse = "%.2f" % (follow_body.metadata.get(entry))
						"affiliation": parse = "%s" % game_data.UNIT_AFFILIATIONS.find_key(follow_body.metadata.get(entry))
						_: parse = str(follow_body.metadata.get(entry))
					body_attributes_list.add_item("%s : %s" % [entry, parse], null, false)
	
	#PICKER UTILITY \/\/\/\/\/
	if follow_body and follow_body.is_known(): 
		if follow_body.get_type() == starSystemAPI.BODY_TYPES.PLANET: 
			if follow_body.get_current_variation() != -1:
				var data_for_planet_type = system.planet_type_data.get(follow_body.metadata.get("planet_type"))
				var variation_class = data_for_planet_type.get("variation_class")
				if variation_class != null and (follow_body.metadata.get("missing_AO", false) == true):
					picker_label.show()
					picker_button.show()
					picker_label.set_text(str(variation_class.capitalize(), " (AUDIO VISUALIZER): "))
					if follow_body.get_guessed_variation() != -1:
						picker_button.select(follow_body.get_guessed_variation())
					else: picker_button.select(-1)
				else:
					picker_label.hide()
					picker_button.hide()
			else:
				picker_label.hide()
				picker_button.hide()
		else:
			picker_label.hide()
			picker_button.hide()
	else:
		picker_label.hide()
		picker_button.hide() #NEED TO FIX THIS ATROCITY AT SOME POINT!!!!
	
	queue_redraw()
	pass



func calculate_asteroid_belt_slowdown() -> void:
	var i: int = 0
	var asteroid_belts = system.get_bodies_of_body_type(starSystemAPI.BODY_TYPES.ASTEROID_BELT)
	if asteroid_belts:
		for belt in asteroid_belts:
			var lower_echelon = belt.orbit_distance - belt.metadata.get("belt_width") / 2
			var upper_echelon = belt.orbit_distance + belt.metadata.get("belt_width") / 2
			var distance = player_position_matrix[0].distance_to(belt.position)
			if distance > lower_echelon and distance < upper_echelon:
				i += 1
				break
	if i == 0:
		player_in_asteroid_belt = false
	elif i > 0:
		player_in_asteroid_belt = true
	pass

func calculate_pulsar_beam_slowdown_and_damage(delta) -> void:
	var i: int = 0
	if system.get_first_star() is pulsarBodyAPI:
		var _star = system.get_first_star()
		var points = get_pulsar_beams_as_points(_star)
		for beam in points:
			if Geometry2D.is_point_in_polygon(player_position_matrix[0], beam):
				i += 1
				break
	if i == 0:
		player_in_pulsar_beam = false
	if i > 0: 
		player_in_pulsar_beam = true
	
	PULSAR_DAMAGE_COOLDOWN = maxf(0, PULSAR_DAMAGE_COOLDOWN - delta)
	if player_in_pulsar_beam and PULSAR_DAMAGE_COOLDOWN == 0:
		PULSAR_DAMAGE_COOLDOWN = PULSAR_MAX_DAMAGE_COOLDOWN
		emit_signal("playerInPulsarBeamCooldownExpired")
	pass



func generate_system_list() -> void:
	system_list.clear()
	recursive_add(system.get_first_star(), null) #RECUSION IS SO COOL
	pass

func recursive_add(body: bodyAPI, parent: TreeItem) -> void:
	if body != null:
		var new = create_item_for_body(body, parent)
		
		var sub_bodies = sort_sub_bodies_by_distance(body, system.get_bodies_with_hook_identifier(body.get_identifier()))
		for b in sub_bodies:
			recursive_add(b, new)
	pass

func create_item_for_body(body: bodyAPI, parent: TreeItem) -> TreeItem:
	if not body.is_hidden():
		var item: TreeItem = system_list.create_item(parent)
		item.set_metadata(0, body.get_identifier())
		
		if body.is_theorised_not_known():
			item.set_text(0, "???")
			
			if body == follow_body:
				item.set_custom_bg_color(0, Color.DARK_SLATE_GRAY.lightened(0.5)) #LIGHT_SKY_BLUE
			elif body.get_identifier() == closest_body_id: 
				item.set_custom_bg_color(0, Color.DARK_SLATE_GRAY.lightened(0.2)) #WEB_GRAY
			else:
				item.set_custom_bg_color(0, Color.DARK_SLATE_GRAY)
		
		elif body.is_known():
			
			if body == follow_body:
				item.set_custom_bg_color(0, Color.DARK_SLATE_GRAY.lightened(0.5)) #LIGHT_SKY_BLUE
			elif body.get_identifier() == closest_body_id: 
				item.set_custom_bg_color(0, Color.DARK_SLATE_GRAY.lightened(0.2)) #WEB_GRAY
			else:
				item.set_custom_bg_color(0, Color.DARK_SLATE_GRAY)
			
			item.set_text(0, body.get_display_name())
			item.set_icon(0, empty_frame)
			
			match body.get_type():
				starSystemAPI.BODY_TYPES.STAR:
					#item.set_text(0, "%s - %s Class Star" % [body.get_display_name(), body.metadata.get("star_type")])
					item.set_icon(0, load("uid://d0r4v5pr3cutt"))
					item.set_tooltip_text(0, "%s - %s Class Star" % [item.get_text(0), body.metadata.get("star_type")])
					
					if body == follow_body:
						item.set_custom_bg_color(0, Color(0.18, 0.18, 0.18, 0.416).lightened(0.5))
					elif body.get_identifier() == closest_body_id:
						item.set_custom_bg_color(0, Color(0.18, 0.18, 0.18, 0.416).lightened(0.2))
					else:
						item.set_custom_bg_color(0, Color(0.18, 0.18, 0.18, 0.416))
					
				starSystemAPI.BODY_TYPES.PLANET:
					#item.set_text(0, "%s - %s Planet" % [body.get_display_name(), body.metadata.get("planet_type")])
					item.set_icon(0, get_planet_frame(body.metadata.get("planet_classification")))
					item.set_tooltip_text(0, "%s - %s Planet" % [item.get_text(0), body.metadata.get("planet_type")])
					
					if (body.metadata.get("planetary_anomaly", false) == true) and (body.metadata.get("planetary_anomaly_available", false) == true):
						item.set_icon(0, question_mark_frame)
						oscillate_item_icon_color(item, Color.GREEN)
					elif (body.metadata.get("missing_GL", false) == true) and (player_gas_layer_surveyor_unlocked == true):
						item.set_icon(0, load("uid://dmutb3ak7n4l2"))
						item.set_icon_modulate(0, Color.GREEN.darkened(0.4))
					elif (body.metadata.get("missing_AO", false) == true) and (body.get_guessed_variation() == -1) and (player_audio_visualizer_unlocked == true): #body.get_guessed_variation() will be a function in planetAPI or circularBodyAPI
						item.set_icon(0, load("uid://pbgoomdkkj6h"))
						item.set_icon_modulate(0, Color.GREEN.darkened(0.4))
					
					#if body.is_habitable():
					#	item.set_custom_color(0, Color.GREEN)
					
				starSystemAPI.BODY_TYPES.WORMHOLE:
					item.set_icon(0, load("uid://k50rbp6ri57u"))
					
					const disabled_color = Color("#7f4b4b")
					
					match body.is_disabled(): #is_disabled() will be a function in new wormholeAPI
						true:
							if body == follow_body:
								item.set_custom_bg_color(0, disabled_color.lightened(0.5))
							elif body.get_identifier() == closest_body_id:
								item.set_custom_bg_color(0, disabled_color.lightened(0.2))
							else:
								item.set_custom_bg_color(0, disabled_color)
						false:
							if body == follow_body:
								item.set_custom_bg_color(0, Color.WEB_PURPLE.lightened(0.5))
							elif body.get_identifier() == closest_body_id:
								item.set_custom_bg_color(0, Color.WEB_PURPLE.lightened(0.2))
							else:
								item.set_custom_bg_color(0, Color.WEB_PURPLE)
					
				starSystemAPI.BODY_TYPES.STATION:
					item.set_icon(0, load("uid://csrl0hs7rc0hn"))
					
				starSystemAPI.BODY_TYPES.SPACE_ANOMALY:
					if body.metadata.get("space_anomaly_available", true) == true:
						item.set_icon(0, question_mark_frame)
						oscillate_item_icon_color(item, Color.GREEN)
					
				starSystemAPI.BODY_TYPES.SPACE_ENTITY:
					item.set_text(0, game_data.ENTITY_CLASSIFICATIONS.find_key(body.entity_classification).capitalize())
					item.set_icon(0, game_data.get_entity_frame(body.entity_classification))
					
				starSystemAPI.BODY_TYPES.RENDEZVOUS_POINT:
					item.set_icon(0, load("uid://hdeudc7u2rsm"))
					
				starSystemAPI.BODY_TYPES.CUSTOM:
					var icon: Object
					if body.is_available(): icon = load(body.icon_path)
					else: icon = load(body.post_icon_path)
					item.set_icon(0, icon)
					
		
		var c = collapsed_cache.get(body.get_identifier())
		if c != null:
			item.set_collapsed(c)
		
		return item
	return null

func clear_system_list_caches() -> void:
	print("SYSTEM MAP: CLEARING SYSTEM LIST CACHES")
	collapsed_cache.clear()
	pass

func sort_sub_bodies_by_distance(body: bodyAPI, sub_bodies: Array) -> Array:
	var to_sort = sub_bodies.duplicate()
	
	var n = len(to_sort)
	for i in range(1,n):
		var insert_index = i
		var current_body = to_sort.pop_at(i)
		var current_distance = current_body.position.distance_to(body.position)
		for j in range(i-1, -1, -1):
			if to_sort[j].position.distance_to(body.position) > current_distance:
				insert_index = j
		to_sort.insert(insert_index, current_body)
	
	return to_sort



func update_contact_list() -> void:
	var root = contact_list.get_root() as TreeItem
	for item in root.get_children():
		var identifier = item.get_metadata(0)
		var body = system.get_body_from_identifier(identifier)
		if body != null:
			
			if body == follow_body:
				item.set_custom_bg_color(0, Color.DARK_SLATE_GRAY.lightened(0.5)) #LIGHT_SKY_BLUE
			elif body.get_identifier() == closest_body_id: 
				item.set_custom_bg_color(0, Color.DARK_SLATE_GRAY.lightened(0.2)) #WEB_GRAY
			else:
				item.set_custom_bg_color(0, Color.DARK_SLATE_GRAY)
			
			if body.is_hostile():
				if body == follow_body:
					item.set_custom_bg_color(0, Color.DARK_RED.lightened(0.5)) #LIGHT_SKY_BLUE
				elif body.get_identifier() == closest_body_id: 
					item.set_custom_bg_color(0, Color.DARK_RED.lightened(0.2)) #WEB_GRAY
				else:
					item.set_custom_bg_color(0, Color.DARK_RED)
			
			if body.get_type() == starSystemAPI.BODY_TYPES.SHIP: #i ont like this :( but it works !
				if body.metadata.get("ship_available", true) == false:
					item.set_icon_overlay(0, null)
			
		else:
			item.free()
	pass

func _on_player_scanner_contact_gained(unit: unitBodyAPI) -> void:
	unit.known = true
	_on_found_body(unit.get_identifier())
	var item: TreeItem = contact_list.create_item(contact_list.get_root())
	item.set_metadata(0, unit.get_identifier())
	item.set_text(0, unit.get_display_name())
	
	if unit.is_hostile():
		item.set_icon(0, load("uid://dxtvjut27oly0"))
	else:
		item.set_icon(0, load("uid://bbdpqnpgh7iy6"))
	
	if unit.get_type() == starSystemAPI.BODY_TYPES.SHIP:
		if unit.metadata.get("ship_available", true) == true:
			item.set_icon_overlay(0, load("uid://b205ybcemhe36"))
	pass

func _on_player_scanner_contact_lost(unit: unitBodyAPI) -> void:
	unit.known = false
	var root = contact_list.get_root() as TreeItem
	for item in root.get_children():
		if item.get_metadata(0) == unit.get_identifier():
			item.free()
			break
	pass



#what the hell are these functions (the area)
func oscillate_item_icon_color(item: TreeItem, color: Color, c: int = 0) -> void:
	item.set_icon_modulate(c, color * maxf(sin(Time.get_unix_time_from_system()), 0.75))
	pass

func update_alarm_sound(data: Array = []) -> void:
	if data.size() == 2:
		var danger = data[0]
		var distance = data[1]
		
		match danger:
			true:
				if not alarm_sound.is_playing():
					alarm_sound.set_playing(true)
				alarm_sound.set_pitch_scale(clampf(remap(distance, 30.0, 0.0, 1.0, 2.0), 1.0, 2.0))
			false:
				alarm_sound.set_playing(false)
	pass

func update_proximity_blinker(_active: bool) -> void:
	proximity_blinker.active = _active
	pass



func _unhandled_input(event):
	var zoom_multiplier = pow(camera.zoom.length(), -1.0)
	var standard_size = zoom_multiplier * 10.0
	
	if event.is_action_pressed("SC_INTERACT2_RIGHT_MOUSE"):
		var closest_body = global_data.get_closest_body(system.bodies, get_global_mouse_position())
		if get_global_mouse_position().distance_to(closest_body.position) < (1 + standard_size) \
		and (not closest_body.is_not_known_or_is_hidden()) \
		and (not closest_body is unitBodyAPI):
			emit_signal("updatedLockedBody", closest_body)
			locked_body = closest_body
			follow_body = closest_body
			camera.follow_body = closest_body
			follow_body_modifier = closest_body
			action_body = closest_body
			emit_signal("updatePlayerActionType", playerAPI.ACTION_TYPES.ORBIT, action_body)
			async_add_movement_ping(closest_body.position, closest_body)
			return
		
		locked_body = null
		action_body = null
		emit_signal("updatePlayerTargetPosition", get_global_mouse_position())
		emit_signal("updatePlayerActionType", playerAPI.ACTION_TYPES.NONE, null)
		async_add_movement_ping(get_global_mouse_position())
		get_tree().call_group("eventsHandler", "speak", self, "player_target_position_update")
	
	if event.is_action_pressed("SC_INTERACT1_LEFT_MOUSE"):
		var closest_body = global_data.get_closest_body(system.bodies, get_global_mouse_position())
		if get_global_mouse_position().distance_to(closest_body.position) < (1 + standard_size) \
		and (not closest_body.is_not_known_or_is_hidden()):
			emit_signal("updatedLockedBody", closest_body)
			locked_body = closest_body
			follow_body = closest_body
			camera.follow_body = closest_body
			follow_body_modifier = closest_body
			return
		
		camera_target_position = get_global_mouse_position()
		follow_body_modifier = null
		emit_signal("updateTargetPosition", get_global_mouse_position())
		emit_signal("lockedBodyDepreciated")
	
	if event.is_action_pressed("SC_BOOST"):
		player_is_boosting = true
		emit_signal("updatePlayerIsBoosting", player_is_boosting)
		play_boost_sound(BOOST_SOUND_TYPES.START)
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE, "eventsHandler", "speak", self, "player_boosting_start")
	elif event.is_action_released("SC_BOOST"):
		player_is_boosting = false
		emit_signal("updatePlayerIsBoosting", player_is_boosting)
		play_boost_sound(BOOST_SOUND_TYPES.END)
	
	if event.is_action_pressed("SC_OPEN_HELP_OVERLAY"):
		help_overlay.show()
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE, "eventsHandler", "speak", self, "help_overlay_show")
	elif event.is_action_released("SC_OPEN_HELP_OVERLAY"):
		help_overlay.hide()
	
	if event.is_action_released("SC_SCOPE_SWITCH"):
		if enable_scope_mode_switch.is_stopped():
			emit_signal("toggleScopeModeSwitchButton")
	pass

func reset_player_boosting() -> void:
	player_is_boosting = false
	emit_signal("updatePlayerIsBoosting", player_is_boosting)
	pass

func reset_actions_buttons_pressed() -> void: #godot 4.3 migration issue quickfix... terrible...
	orbit_button._on_button_up()
	go_to_button._on_button_up()
	stop_button._on_button_up()
	pass

func _draw():
	draw_map()
	draw_sonar()
	draw_movement()
	draw_text()
	draw_CME()
	draw_pulsar_beams()
	pass

func draw_sonar():
	var zoom_multiplier = pow(camera.zoom.length(), -1.0)
	if SONAR_POLYGON_DISPLAY_TIME != 0 and SONAR_POLYGON:
		draw_colored_polygon(SONAR_POLYGON, Color.DARK_GRAY)
	for ping in SONAR_PINGS:
		ping.updateDisplay()
		draw_circle(ping.position, zoom_multiplier * 10.0 * ping.current_radius, ping.current_color)
	pass

func draw_movement() -> void: # draw movement pings (manual set course)
	var zoom_multiplier = pow(camera.zoom.length(), -1.0)
	
	for ping in MOVEMENT_PINGS:
		ping.updateDisplay()
		var size = zoom_multiplier * 40.0 * ping.current_radius
		target_texture.draw_rect(
			get_canvas_item(),
			global_data.get_offset_rect2(ping.position, size, size), 
			false,
			ping.current_color
		)
	pass

func draw_text() -> void:
	var zoom_multiplier = pow(camera.zoom.length(), -1.0)
	
	for ping in TEXT_PINGS:
		ping.updateDisplay()
		var size = maxi(2, roundi(zoom_multiplier * 4.0 * ping.current_radius))
		default_font.draw_string(
			get_canvas_item(),
			ping.position,
			ping.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			size,
			ping.current_color,
			TextServer.JUSTIFICATION_NONE,
			TextServer.DIRECTION_AUTO,
			TextServer.ORIENTATION_HORIZONTAL,
			16.0
		)
	
	pass

func draw_CME():
	if CME_RING_SHOWN:
		draw_circle(Vector2.ZERO, CME_RING_RADIUS, Color.WHITE.darkened(remap(float(CME_RING_RADIUS), float(), float(CME_MAX_RING_RADIUS), 0.0, 1.0)), false, 10)
	pass

func draw_pulsar_beams():
	randomize()
	if system.get_first_star() is pulsarBodyAPI:
		var _star = system.get_first_star() as pulsarBodyAPI
		var points_top = get_pulsar_beams_as_points(_star)
		var points_backdrop = get_pulsar_beams_as_points(_star)
		
		var tip_color = Color.WHITE
		tip_color.a = sin(_star.beam_rotation * _star.beam_width)
		
		var cols_top: PackedColorArray = [Color.WHITE, tip_color, tip_color]
		var cols_backdrop: PackedColorArray = []
		cols_backdrop.resize(3)
		cols_backdrop.fill(Color(Color.DIM_GRAY, 0.35))
		
		draw_polygon(points_backdrop[0], cols_backdrop)
		draw_polygon(points_backdrop[1], cols_backdrop)
		draw_polygon(points_top[0], cols_top)
		draw_polygon(points_top[1], cols_top)
	pass
func get_pulsar_beams_as_points(star: pulsarBodyAPI) -> Array[PackedVector2Array]:
	var dir1 = Vector2.UP.rotated(star.beam_rotation)
	var ex1 = dir1 + Vector2(0, -500).rotated(star.beam_rotation)
	var a1 = dir1 + Vector2(0, -star.radius * 4.0).rotated(star.beam_rotation)
	var b1 = ex1 + Vector2(0,star.beam_width).rotated(Vector2.ZERO.angle_to_point(ex1))
	var c1 = ex1 + Vector2(0,-star.beam_width).rotated(Vector2.ZERO.angle_to_point(ex1))
	var points1: PackedVector2Array = [a1, b1, c1]
	var points2: PackedVector2Array = [-a1, -b1, -c1]
	return [points1, points2]

func draw_map():
	var zoom_multiplier = pow(camera.zoom.length(), -1.0)
	var standard_size = zoom_multiplier * 10.0
	
	#SHOW STAR HABITALBE ZONE --->
	#draw_arc(Vector2.ZERO, ((sqrt((system.get_first_star().metadata.get("luminosity") * 0.53))) * 215), -TAU, TAU, 20, Color.YELLOW, 2)
	#draw_arc(Vector2.ZERO, ((sqrt((system.get_first_star().metadata.get("luminosity") * 1.1))) * 215), -TAU, TAU, 20, Color.YELLOW, 2)
	
	var scanner_power_points: PackedVector2Array = []
	var scanner_power_point_count: int = 30
	for i in scanner_power_point_count:
		var theta = (360 / scanner_power_point_count) * i
		var dir = Vector2.UP.rotated(deg_to_rad(theta))
		var pos = Vector2(player_position_matrix[0] + (dir * player_adj_scanner_matrix[1]))
		scanner_power_points.append(pos)
	
	var asteroid_belts = system.get_bodies_of_body_type(starSystemAPI.BODY_TYPES.ASTEROID_BELT)
	if asteroid_belts: 
		for belt in asteroid_belts:
			if belt.is_known(): 
				draw_arc(belt.position, belt.orbit_distance, -10, TAU, 50, belt.metadata.get("belt_color"), belt.metadata.get("belt_width"), false)
	
	var mines = system.get_bodies_of_body_type(starSystemAPI.BODY_TYPES.MINE)
	if mines:
		for mine in mines:
			var _exclusion_radius_points: PackedVector2Array = []
			if mine.exclusion_radius_points.size() > 0:
				_exclusion_radius_points = mine.exclusion_radius_points
			else:
				var point_count: int = 12
				for i in point_count:
					var theta = (360 / point_count) * i
					var dir = Vector2.UP.rotated(deg_to_rad(theta))
					var pos = Vector2(mine.position + (dir * mine.metadata.get("exclusion_zone_radius")))
					_exclusion_radius_points.append(pos)
				mine.exclusion_radius_points = _exclusion_radius_points
			
			var intersected_points = Geometry2D.intersect_polygons(scanner_power_points, _exclusion_radius_points)
			var offset_points = Geometry2D.offset_polygon(_exclusion_radius_points, -(mine.metadata.get("exclusion_zone_radius") * remap(mine.detonation_time_index, 0.0, 1.0, 1.0, 0.0)))
			
			if intersected_points.size() > 0:
				if not intersected_points[0].size() < 3:
					draw_colored_polygon(intersected_points[0], Color(Color.DARK_RED.darkened(0.75), 0.5))
			
			if offset_points.size() > 0:
				var intersected_offset_points = Geometry2D.intersect_polygons(scanner_power_points, offset_points[0])
				if intersected_offset_points.size() > 0:
					if not intersected_offset_points[0].size() < 3:
						draw_colored_polygon(intersected_offset_points[0], Color.DARK_RED.darkened(0.5))
	
	if scanner_profile_time > 0:
		draw_arc(player_position_matrix[0], player_adj_scanner_matrix[0], -TAU, TAU, 30, Color("#7f4b4b", clampf(remap(scanner_profile_time, 0.0, 1.0, 0.0, 0.25), 0.0, 0.25)), 0.5, false)
	if scanner_power_time > 0:
		draw_multiline(scanner_power_points, Color(0.98039216, 0.92156863, 0.84313726, clampf(remap(scanner_power_time, 0.0, 1.0, 0.0, 0.1), 0.0, 0.1)), 0.2, false)
	
	for body in system.bodies:
		
		#batch customBodyAPI texture drawing
		
		if body is customBodyAPI and body.is_known():
			var texture: Object
			if body.is_available(): texture = load(body.texture_path)
			else: texture = load(body.post_texture_path)
			texture.draw_rect(get_canvas_item(), global_data.get_offset_rect2(body.position, standard_size, standard_size), false)
	
	for body in system.bodies:
		
		#batch orbit line drawing:
		
		if body is circularBodyAPI and body.is_known():
			if system.get_body_from_identifier(body.hook_identifier):
				draw_arc(system.get_body_from_identifier(body.hook_identifier).position, body.orbit_distance, -TAU, TAU, 30, Color(0.23529411764705882, 0.43137254901960786, 0.44313725490196076, 0.2), 1.0, false)
	
	for body in system.bodies:
		
		#batching circle drawing:
		
		if body is circularBodyAPI and body.is_known():
			if body == follow_body:
				draw_circle(body.position, standard_size * 1.75, body.surface_color.lerp(Color(1.0, 1.0, 1.0, 0.0), 0.50))
				draw_circle(body.position, standard_size, body.surface_color)
			elif body.get_identifier() == closest_body_id:
				draw_circle(body.position, standard_size * 1.5, body.surface_color.lerp(Color(1.0, 1.0, 1.0, 0.0), 0.75))
				draw_circle(body.position, standard_size, body.surface_color)
			else:
				draw_circle(body.position, standard_size, body.surface_color)
		
	for body in system.bodies:
		
		#batching entity icons:
		
		if body is glintBodyAPI and body.is_known():
			entity_texture.draw_rect(get_canvas_item(), global_data.get_offset_rect2(body.position, standard_size * 1.5, standard_size * 1.5), false, Color.LIGHT_GRAY)
	
	for body in system.bodies:
		
		#INCORRECTLY batch unitBodyAPI drawing (applies two different draws at once, removing any possible benefit of batching)
		
		if body is unitBodyAPI and body.is_known(): #what it should be is this: unitBodyAPIs are usually not drawn, like bodyAPIs, but AIUnitAPIs are always drawn. but this probably isnt good idea. so, therefore, we need to check that the unit is NOT custom when drawing this when we add that feature
			var self_color = Color.SLATE_GRAY
			var blink_color = Color.LIGHT_GRAY
			if body.is_hostile():
				self_color = Color.RED
				blink_color = Color.DARK_RED
			
			draw_arc(body.position, standard_size * maxf(0.25, sin(Time.get_unix_time_from_system() * 4.0)), -TAU, TAU, 5, blink_color, standard_size, false)
			draw_rect(global_data.get_offset_rect2(body.position, standard_size, standard_size), self_color)
	
	for body in system.bodies:
		
		#batching anomaly map icons:
		
		if body.get_type() == starSystemAPI.BODY_TYPES.PLANET and body.is_known(): 
			if body.is_PA_valid():
				var rect = global_data.get_offset_rect2(body.position, standard_size * 2, standard_size * 2)
				rect.position += Vector2(standard_size * 1.5, standard_size * 1.5)
				question_mark_texture.draw_rect(get_canvas_item(), rect, false)
		elif body.get_type() == starSystemAPI.BODY_TYPES.SPACE_ANOMALY and body.is_known(): 
			if body.is_SA_valid():
				var rect = global_data.get_offset_rect2(body.position, standard_size * 2, standard_size * 2)
				rect.position += Vector2(standard_size * 1.5, standard_size * 1.5)
				question_mark_texture.draw_rect(get_canvas_item(), rect, false)
	
	#drawing player and player trajectory and player look direction
	draw_line(player_position_matrix[0], player_position_matrix[1], Color.ANTIQUE_WHITE, zoom_multiplier * 2)
	draw_rect(global_data.get_offset_rect2(player_position_matrix[0], standard_size, standard_size), Color.WHITE)
	if camera_target_position != Vector2.ZERO:
		draw_circle(camera_target_position, zoom_multiplier * 2, Color.LIGHT_SKY_BLUE)
		draw_line(player_position_matrix[0], player_position_matrix[0] + (player_position_matrix[0].direction_to(camera_target_position) * 100.0), Color.LIGHT_SKY_BLUE, zoom_multiplier * 2)
	pass



func _on_go_to_button_pressed():
	if locked_body:
		action_body = locked_body
		emit_signal("updatePlayerActionType", playerAPI.ACTION_TYPES.GO_TO, action_body)
		async_add_movement_ping(action_body.position, action_body)
	pass

func _on_orbit_button_pressed():
	#not sure who will have jurisdiction
	if locked_body:
		action_body = locked_body
		emit_signal("updatePlayerActionType", playerAPI.ACTION_TYPES.ORBIT, action_body)
		async_add_movement_ping(action_body.position, action_body)
	pass

func _on_stop_button_pressed():
	locked_body = null
	action_body = null
	emit_signal("updatePlayerTargetPosition", player_position_matrix[0])
	emit_signal("updatePlayerActionType", playerAPI.ACTION_TYPES.NONE, null)
	pass



func _on_sonar_ping(ping_width: int, ping_length: int, ping_direction: Vector2):
	var line = player_position_matrix[0] + ping_direction * ping_length
	
	var a = player_position_matrix[0]
	var b = line + Vector2(0,ping_width).rotated(player_position_matrix[0].angle_to_point(line))
	var c = line + Vector2(0,-ping_width).rotated(player_position_matrix[0].angle_to_point(line))
	var points: PackedVector2Array = [a,b,c]
	
	SONAR_POLYGON = points
	SONAR_POLYGON_DISPLAY_TIME = 50
	
	var ping_hit: bool = false
	
	for body in system.bodies:
		if body.is_hidden():
			continue
		
		if Geometry2D.is_point_in_polygon(body.position, points):
			if body is orbitBodyAPI:
				async_add_ping(body)
				
				if not body.is_hidden():
					if not body.is_theorised():
						ping_hit = true
				
			elif body is unitBodyAPI:
				async_add_unit_ping(body, ping_width)
	
	emit_signal("documentPingHitStatus", ping_hit)
	
	#random pings \/\/\/\/
	#for random_ping in global_data.get_randi(0, remap(ping_width, 5, 90, 0, 10)):
		#var ping = load("res://Data/Ping Display Helpers/normal.tres").duplicate(true)
		#ping.position = global_data.random_triangle_point(a,b,c)
		#ping.resetTime()
		#SONAR_PINGS.append(ping)
	
	get_tree().call_group("audioHandler", "play_once", LIDAR_ping, 0.0, "SFX")
	pass

func async_add_ping(body: orbitBodyAPI) -> void:
	await get_tree().create_timer((player_position_matrix[0].distance_to(body.position) / 100)).timeout
	
	body.pings_to_be_theorised = maxi(0, body.pings_to_be_theorised - 1)
	if body.pings_to_be_theorised == 0:
		if not body.theorised:
			emit_signal("theorisedBody", body.get_identifier())
		body.theorised = true #so it says '???' on the overview
	var pings = ["res://data/system-map/ping-display-helpers/normal.tres"]
	var ping = load(pings.pick_random()).duplicate(true)
	ping.position = body.position
	ping.resetTime()
	SONAR_PINGS.append(ping)
	
	get_tree().call_group("audioHandler", "play_once", LIDAR_bounceback, 0.0, "SFX")
	pass

func async_add_unit_ping(unit: unitBodyAPI, _ping_width: int) -> void:
	await get_tree().create_timer((player_position_matrix[0].distance_to(unit.position) / 100)).timeout
	
	var ping = load("uid://do24617ugegbj").duplicate(true)
	ping.position = unit.position
	ping.resetTime()
	SONAR_PINGS.append(ping)
	
	if unit is AIUnitAPI:
		if player_position_matrix[0].distance_to(unit.position) < player_adj_scanner_matrix[1]: #distance below power
			var duration = remap(_ping_width, 5, 90, 7.5, 1.5)
			unit.stun(duration)
			if unit.is_hostile() and (not unit is mineUnitAPI):
				_on_add_text_ping("res://data/system-map/ping-display-helpers/text_stun.tres", unit.position, "Stunned!(%.1fs)" % duration)
			get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE, "eventsHandler", "speak", self, "player_stun_unit")
	
	get_tree().call_group("audioHandler", "play_once", LIDAR_bounceback, 0.0, "SFX")
	pass

func async_add_movement_ping(pos: Vector2, body: bodyAPI = null) -> void: #manual targeting n shit
	var ping: pingDisplayHelper = load("uid://rt20q5blyny2").duplicate(true)
	ping.position = pos
	ping.resetTime()
	if body:
		body.connect("position_updated", ping.updatePosition)
	MOVEMENT_PINGS.append(ping)
	pass



func play_boost_sound(sound_type: BOOST_SOUND_TYPES):
	match sound_type:
		BOOST_SOUND_TYPES.START:
			get_tree().call_group("audioHandler", "play_once", boost_start, -24, "SFX")
		BOOST_SOUND_TYPES.END:
			get_tree().call_group("audioHandler", "play_once", boost_end, -24, "SFX")
	pass

func reset_camera_follow_body() -> void:
	camera.follow_body = null
	pass

func _on_sonar_values_changed(ping_width: int, ping_length: int, ping_direction: Vector2): #for SCAN_PREDICTION upgrade!
	scan_prediction_upgrade._on_sonar_values_changed(ping_width, ping_length, ping_direction)
	pass

func _on_remove_hull_stress_for_nanites(amount: int, nanites_per_percentage: int) -> void:
	emit_signal("removeHullStressForNanites", amount, nanites_per_percentage)
	pass

func get_planet_frame(classification: String) -> Resource:
	match classification:
		"Terran":
			return load("uid://u5b3uh7kbj25")
		"Neptunian":
			return load("uid://ddxxk0gbwi37a")
		"Jovian":
			return load("uid://dt4ghhmgofelr")
	return null

func _on_found_body(id: int):
	var body = system.get_body_from_identifier(id)
	
	if body.metadata.has("value"):
		_on_add_text_ping("res://data/system-map/ping-display-helpers/text_discovery.tres", body.position, "+%d%c" % [body.metadata.get("value"), "ň"])
	
	match body:
		_ when body is unitBodyAPI:
			var ping = load("uid://xurvu36ugl05").duplicate(true)
			ping.position = body.position
			ping.resetTime()
			SONAR_PINGS.append(ping)
		_ when body is orbitBodyAPI:
			var ping = load("uid://d3ntmvsq6pv83").duplicate(true)
			ping.position = body.position
			ping.resetTime()
			SONAR_PINGS.append(ping)
			
			if body.get_type() == starSystemAPI.BODY_TYPES.PLANET and body.is_PA_valid():
				get_tree().call_group("audioHandler", "play_once", LIDAR_anomaly_discovery, 0.0, "SFX")
			elif body.get_type() == starSystemAPI.BODY_TYPES.SPACE_ANOMALY and body.is_SA_valid():
				get_tree().call_group("audioHandler", "play_once", LIDAR_anomaly_discovery, 0.0, "SFX")
			else:
				get_tree().call_group("audioHandler", "play_once", LIDAR_discovery, 0.0, "SFX")
			
			if body.get_type() == starSystemAPI.BODY_TYPES.PLANET:
				if body.is_habitable():
					get_tree().call_group("audioHandler", "plot_radio", load("uid://crkhwlwd0qqkh"))
	pass

func _on_picker_button_item_selected(index):
	if follow_body.get_type() == starSystemAPI.BODY_TYPES.PLANET:
		follow_body.set_guessed_variation(index)
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE, "eventsHandler", "speak", self, "AV_picker_select")
	pass

func _on_add_console_entry(text: String, text_color: Color = Color.WHITE):
	console.add_entry(text, text_color)
	pass

func _on_clear_console_entries():
	console.clear_entries()
	pass

func _on_player_data_value_changed(new_value: int):
	data_value_increase_label.set_text("%.fň" % new_value)
	if new_value != 0:
		data_value_increase_label.blink()
	pass

func _on_update_countdown_overlay_info(title: String, description: String, hull_stress: int):
	countdown_overlay.update_info(title, description, hull_stress)
	pass

func _on_update_countdown_overlay_time(time: float):
	countdown_overlay.update_time(time)
	pass

func _on_update_countdown_overlay_shown(shown: bool):
	countdown_overlay.set_visible(shown)
	view_objective_label._on_update_countdown_overlay_shown(shown)
	pass

func _on_CME_timeout(_system_id: int):
	CME_RING_RADIUS = int()
	CME_RING_SHOWN = true
	pass

func _on_player_below_CME_ring_radius():
	emit_signal("playerBelowCMERingRadius")
	pass

func _on_countdown_overlay_CME_flash() -> void:
	countdown_overlay._on_CME_flash()
	pass

func _on_update_current_action_display(_type: playerAPI.ACTION_TYPES, _body: bodyAPI, _pending: bool) -> void:
	current_action_label.update(_type, _body, _pending)
	pass

func _on_active_objectives_changed(_active_objectives: Array[objectiveAPI]):
	view_objective_label._on_active_objectives_changed(_active_objectives)
	
	for popup in info_popups.get_children(): #prerttyyy dangerous...
		popup._on_active_objectives_changed(_active_objectives)
	pass

func _on_update_scanner_display_times(new_profile_time: float, new_power_time: float) -> void:
	scanner_profile_time = new_profile_time
	scanner_power_time = new_power_time
	pass

func _on_tutorial_ingress_threshold_reached() -> void:
	emit_signal("tutorialIngressThresholdReached")
	pass

func _on_add_text_ping(ping_path: String, pos: Vector2, text: String) -> void:
	var ping = load(ping_path).duplicate(true)
	ping.position = pos
	ping.text = text
	ping.resetTime()
	TEXT_PINGS.append(ping)
	pass



func setup_tutorial_processor() -> void:
	var processor = load("uid://b4lh43qyyit6h").instantiate()
	add_child(processor)
	tutorial_processor = processor
	processor.connect("tutorialIngressThresholdReached", _on_tutorial_ingress_threshold_reached)
	pass

func setup_tutorial_info_popups() -> void:
	var tutorial = load("uid://cxd20qjvft4hb").instantiate()
	for popup in tutorial.get_children():
		popup.set_owner(null)
		popup.reparent(info_popups, false)
		popup.set_owner(info_popups)
	tutorial.queue_free()
	pass



func _on_audio_visualizer_button_pressed() -> void:
	emit_signal("audioVisualizerPopup")
	pass

func _on_journey_map_button_pressed() -> void:
	emit_signal("journeyMapPopup")
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE, "eventsHandler", "speak", self, "journey_map_open")
	pass 

func _on_long_range_scopes_button_pressed() -> void:
	emit_signal("longRangeScopesPopup")
	pass

func _on_gas_layer_surveyor_button_pressed() -> void:
	emit_signal("gasLayerSurveyorPopup")
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

func _on_contact_list_item_selected() -> void:
	follow_and_lock_item(contact_list.get_selected())
	pass

func follow_and_lock_item(item: TreeItem):
	var identifier: int
	if item: 
		identifier = item.get_metadata(0)
	if identifier:
		var body = system.get_body_from_identifier(identifier)
		match body:
			_ when body is unitBodyAPI:
				if body.is_known():
					emit_signal("updatedLockedBody", body)
					locked_body = body
					follow_body = body
					camera.follow_body = follow_body
					follow_body_modifier = follow_body
			_:
				if body.is_theorised_not_known() or body.is_known():
					emit_signal("updatedLockedBody", body)
					locked_body = body
					follow_body = body
					camera.follow_body = follow_body
					follow_body_modifier = follow_body
	pass



func _on_tabs_tab_changed(tab: int) -> void:
	if tabs.get_tab_title(tab) == "INFO":
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE, "eventsHandler", "speak", self, "system_list_info_tab_select")
	pass

func _on_settings_button_pressed() -> void:
	emit_signal("openPauseMenu")
	pass
