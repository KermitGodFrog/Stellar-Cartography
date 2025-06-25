extends Node
#Handles most game stuff that is not local to child windows, loads data, saves data, the whole thing. child windows must route data through this to change the world/system/player

var init_type: int = 0 #from global data GAME_INIT_TYPES
var init_data: Dictionary = {}
var world: worldAPI

@onready var system_map = $system_window/system
@onready var system_3d = $system_window/system/camera/canvas/control/scopes_snap_scroll/scopes_bg/scopes_margin/scopes_container/system_3d_window/system_3d
@onready var sonar = $system_window/system/camera/canvas/control/scopes_snap_scroll/core_and_value_scroll/core_panel_bg/core_panel_scroll/core_panel/core_margin/core_scroll/sonar_container/sonar_window/sonar_control
@onready var barycenter_visualizer = $system_window/system/camera/canvas/control/scopes_snap_scroll/core_and_value_scroll/core_panel_bg/core_panel_scroll/core_panel/core_margin/core_scroll/barycenter_container/barycenter_visualizer_window/barycenter_control
@onready var audio_visualizer = $audio_visualizer_window/audio_control
@onready var long_range_scopes = $long_range_scopes_window/split/lrs_center/lrs_container/lrs_viewport/long_range_scopes
@onready var lrs_bestiary = $long_range_scopes_window/split/bestiary
@onready var station_ui = $station_window/station_control
@onready var dialogue_manager = $dialogueManager
@onready var journey_map = $journey_map_window/journey_map
@onready var pause_menu = $pauseMenu
@onready var stats_menu = $statsMenu
@onready var wormhole_minigame = $wormhole_minigame_window/minigame_container/minigame_viewport/wormhole_minigame
@onready var pause_mode_handler = $pauseModeHandler
@onready var audio_handler = $audioHandler
@onready var gas_layer_surveyor = $gas_layer_surveyor_window/gas_layer_surveyor
@onready var countdown_processor: Node #quantum state of existing and not existing
@onready var objectives_manager = $objectivesManager

func _ready():
	connect_all_signals()
	
	world = game_data.loadWorld()
	if init_type == global_data.GAME_INIT_TYPES.TUTORIAL:
		world = game_data.createWorld(25, 5, 25, 15, 0.01, 0.05, 0.25, 0.10)
		
		dialogue_manager.dialogue_memory = world.dialogue_memory
		
		var new_player = world.createPlayer(
			init_data.get("name", "Tanaka"), 
			init_data.get("prefix", "Captain"))
		new_player.resetJumpsRemaining()
		
		new_player.current_storyline = playerAPI.STORYLINES.keys().pick_random()
		
		new_player.connect("orbitingBody", _on_player_orbiting_body)
		new_player.connect("followingBody", _on_player_following_body)
		new_player.connect("hullDeteriorationChanged", _on_player_hull_deterioration_changed)
		new_player.connect("moraleChanged", _on_player_morale_changed)
		new_player.connect("dataValueChanged", _on_player_data_value_changed)
		new_player.connect("actionTypePendingOrCompleted", _on_player_action_type_pending_or_completed)
		
		var new: starSystemAPI = load("res://Data/tutorial_system.tres")
		world.star_systems.append(new)
		
		world.player.systems_traversed = 4
		journey_map.generate_up_to_system(world.player.systems_traversed)
		
		_on_switch_star_system(new)
		
		_on_update_player_action_type(playerAPI.ACTION_TYPES.NONE, null)
		world.player.position = Vector2(60, 0)
		world.player.setTargetPosition(world.player.position)
		world.player.updatePosition(get_physics_process_delta_time())
		
		pause_menu.disableSaving() # so savefile cannto be overwriten
		
		await get_tree().create_timer(1.0, true).timeout
		
		var new_query = responseQuery.new()
		new_query.add("concept", "tutorialPlayerStart")
		get_tree().call_group("dialogueManager", "speak", self, new_query)
	
	elif world == null or init_type == global_data.GAME_INIT_TYPES.NEW:
		world = game_data.createWorld(25, 5, 25, 15, 0.01, 0.05, 0.25, 0.10)
		
		dialogue_manager.dialogue_memory = world.dialogue_memory
		
		var new_player = world.createPlayer(
			init_data.get("name", "Tanaka"), 
			init_data.get("prefix", "Captain"))
		new_player.resetJumpsRemaining()
		
		new_player.current_storyline = playerAPI.STORYLINES.keys().pick_random()
		
		new_player.connect("orbitingBody", _on_player_orbiting_body)
		new_player.connect("followingBody", _on_player_following_body)
		new_player.connect("hullDeteriorationChanged", _on_player_hull_deterioration_changed)
		new_player.connect("moraleChanged", _on_player_morale_changed)
		new_player.connect("dataValueChanged", _on_player_data_value_changed)
		new_player.connect("actionTypePendingOrCompleted", _on_player_action_type_pending_or_completed)
		
		#new game stuff
		var ghost: starSystemAPI = _on_create_new_star_system()
		var new: starSystemAPI = _on_create_new_star_system(ghost)
		for i in range(2):
			_on_create_new_star_system(new)
		new.createAuxiliaryCivilized()
		
		_on_switch_star_system(new)
		
		_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, new.get_first_star())
		
		await get_tree().create_timer(1.0, true).timeout
		
		#var new_query = responseQuery.new()
		#new_query.add("concept", "openDialog")
		#new_query.add("id", "station")
		#new_query.add_tree_access("station_classification", str("ABANDONED"))
		#new_query.add_tree_access("is_station_abandoned", true)
		#new_query.add_tree_access("is_station_inhabited", false)
		#get_tree().call_group("dialogueManager", "speak", self, new_query)
		
		var new_query = responseQuery.new()
		new_query.add("concept", "playerStart")
		get_tree().call_group("dialogueManager", "speak", self, new_query)
		
		await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
		
		game_data.saveWorld(world) #so if the player leaves before saving, the save file does not go back to a previous game!
		
		get_tree().call_group("audioHandler", "queue_music", "res://Sound/Music/intro.wav")
		
		#var debug = responseQuery.new()
		#debug.add("concept", "followingBody")
		#debug.add("id", "planetaryAnomaly")
		#debug.add_tree_access("planet_classification", "Terran")
		#debug.add_tree_access("planet_type", "Iron")
		#debug.add_tree_access("player_in_CORE_region", true)
		#get_tree().call_group("dialogueManager", "speak", self, debug)
		
		#_on_unlock_upgrade(playerAPI.UPGRADE_ID.ADVANCED_SCANNING)
		#_on_unlock_upgrade(playerAPI.UPGRADE_ID.AUDIO_VISUALIZER)
		
	
	elif init_type == global_data.GAME_INIT_TYPES.CONTINUE:
		
		dialogue_manager.dialogue_memory = world.dialogue_memory
		
		world.player.connect("orbitingBody", _on_player_orbiting_body)
		world.player.connect("followingBody", _on_player_following_body)
		world.player.connect("hullDeteriorationChanged", _on_player_hull_deterioration_changed)
		world.player.connect("moraleChanged", _on_player_morale_changed)
		world.player.connect("dataValueChanged", _on_player_data_value_changed)
		world.player.connect("actionTypePendingOrCompleted", _on_player_action_type_pending_or_completed)
		
		for i in world.player.current_star_system.destination_systems:
			i.previous_system = world.player.current_star_system #really important  actually
		
		for upgrade in world.player.unlocked_upgrades:
			_on_upgrade_state_change(upgrade, true)
		
		journey_map.generate_up_to_system(world.player.systems_traversed)
		
		objectives_manager.start_receive_active_objectives(world.active_objectives)
		
		_on_switch_star_system(world.player.current_star_system)
	pass

func connect_all_signals() -> void:
	system_map.connect("updatePlayerActionType", _on_update_player_action_type)
	system_map.connect("updatePlayerTargetPosition", _on_update_player_target_position)
	system_map.connect("updatePlayerIsBoosting", _on_update_player_is_boosting)
	system_map.connect("updateTargetPosition", _on_update_target_position)
	system_map.connect("updatedLockedBody", _on_locked_body_updated)
	system_map.connect("lockedBodyDepreciated", _on_locked_body_depreciated)
	system_map.connect("removeHullStressForNanites", _on_remove_hull_stress_for_nanites)
	system_map.connect("theorisedBody", _on_theorised_body)
	system_map.connect("playerBelowCMERingRadius", _on_player_below_CME_ring_radius)
	system_map.connect("updatePlayerInAsteroidBelt", _on_update_player_in_asteroid_belt)
	
	system_map.connect("DEBUG_REVEAL_ALL_WORMHOLES", _ON_DEBUG_REVEAL_ALL_WORMHOLES)
	system_map.connect("DEBUG_REVEAL_ALL_BODIES", _ON_DEBUG_REVEAL_ALL_BODIES)
	system_map.connect("DEBUG_QUICK_ADD_NANITES", _ON_DEBUG_QUICK_ADD_NANITES)
	
	system_3d.connect("foundBody", _on_found_body)
	system_3d.connect("addConsoleEntry", _on_add_console_entry)
	
	sonar.connect("sonarPing", _on_sonar_ping)
	sonar.connect("sonarValuesChanged", _on_sonar_values_changed)
	
	station_ui.connect("sellExplorationData", _on_sell_exploration_data)
	station_ui.connect("upgradeShip", _on_upgrade_ship)
	station_ui.connect("addSavedAudioProfile", _on_add_saved_audio_profile)
	station_ui.connect("removeHullStressForNanites", _on_remove_hull_stress_for_nanites)
	station_ui.connect("addPlayerValue", _on_add_player_value)
	
	audio_visualizer.connect("removeSavedAudioProfile", _on_remove_saved_audio_profile)
	
	long_range_scopes.connect("addPlayerValue", _on_add_player_value)
	
	system_map.connect("audioVisualizerPopup", _on_audio_visualizer_popup)
	system_map.connect("journeyMapPopup", _on_journey_map_popup)
	system_map.connect("longRangeScopesPopup", _on_long_range_scopes_popup)
	system_map.connect("gasLayerSurveyorPopup", _on_gas_layer_surveyor_popup)
	
	dialogue_manager.connect("openLRS", _on_open_LRS)
	dialogue_manager.connect("openGLS", _on_open_GLS)
	dialogue_manager.connect("decreasePlayerBalance", _on_decrease_player_balance)
	dialogue_manager.connect("addPlayerValue", _on_add_player_value)
	dialogue_manager.connect("addPlayerHullStress", _on_add_player_hull_stress)
	dialogue_manager.connect("removePlayerHullStress", _on_remove_player_hull_stress)
	dialogue_manager.connect("addPlayerMorale", _on_add_player_morale)
	dialogue_manager.connect("removePlayerMorale", _on_remove_player_morale)
	dialogue_manager.connect("killCharacterWithOccupation", _on_kill_character_with_occupation)
	dialogue_manager.connect("foundBody", _on_found_body)
	dialogue_manager.connect("addPlayerMutinyBacking", _on_add_player_mutiny_backing)
	dialogue_manager.connect("TUTORIALSetIngressOverride", _on_tutorial_set_ingress_override)
	dialogue_manager.connect("TUTORIALSetOmissionOverride", _on_tutorial_set_omission_override)
	dialogue_manager.connect("TUTORIALPlayerWin", _on_tutorial_player_win)
	
	pause_menu.connect("saveWorld", _on_save_world)
	pause_menu.connect("saveAndQuit", _on_save_and_quit)
	pause_menu.connect("exitToMainMenu", _on_exit_to_main_menu)
	
	stats_menu.connect("statsMenuQuit", _on_stats_menu_quit)
	
	wormhole_minigame.connect("addPlayerHullStress", _on_add_player_hull_stress)
	
	objectives_manager.connect("activeObjectivesChanged", _on_active_objectives_changed)
	objectives_manager.connect("updateObjectivesPanel", _on_update_objectives_panel)
	
	gas_layer_surveyor.connect("addPlayerValue", _on_add_player_value)
	
	pause_mode_handler.connect("pauseModeChanged", _on_pause_mode_changed)
	stats_menu.connect("queuePauseMode", _on_queue_pause_mode)
	pause_menu.connect("queuePauseMode", _on_queue_pause_mode)
	dialogue_manager.connect("queuePauseMode", _on_queue_pause_mode)
	station_ui.connect("queuePauseMode", _on_queue_pause_mode)
	wormhole_minigame.connect("queuePauseMode", _on_queue_pause_mode)
	audio_handler.connect("queuePauseMode", _on_queue_pause_mode) #audio handler doesnt TECHNICALLY need pause control
	system_map.connect("queuePauseMode", _on_queue_pause_mode) #for hiding when in dialogue
	objectives_manager.connect("queuePauseMode", _on_queue_pause_mode) #not for anything beyond pausing objective time variable incrase and sending updated objectives - not best practice
	stats_menu.connect("setPauseMode", _on_set_pause_mode)
	pause_menu.connect("setPauseMode", _on_set_pause_mode)
	dialogue_manager.connect("setPauseMode", _on_set_pause_mode)
	station_ui.connect("setPauseMode", _on_set_pause_mode)
	wormhole_minigame.connect("setPauseMode", _on_set_pause_mode)
	audio_handler.connect("setPauseMode", _on_set_pause_mode) #audio handler doesnt TECHNICALLY need pause control
	system_map.connect("setPauseMode", _on_set_pause_mode) #for hiding when in dialogue
	objectives_manager.connect("setPauseMode", _on_set_pause_mode) #not for anything beyond pausing objective time variable incrase and sending updated objectives - not best practice
	pass

func _physics_process(delta):
	#EVERYTHING HERE MUST ONLY FUNCTION WHEN THE GAME IS UNPAUSED!
	
	#CORE GAME LOGIC \/\/\/\/\/
	#updating positions of everyhthing for API's
	world.player.updateActionBodyState()
	world.player.updatePosition(delta)
	var current_bodies = world.player.current_star_system.bodies
	if current_bodies:
		for body in current_bodies:
			world.player.current_star_system.updateBodyPosition(body.get_identifier(), delta)
			body.advance(delta) #capacity to do more stuff, can be overriden by classes that inherit bodyAPI
	
	#updating positions of everyhthing for windows
	system_map.set("player_position_matrix", [world.player.position, world.player.target_position])
	system_map.set("_player_status_matrix", [world.player.balance, world.player.hull_stress, world.player.hull_deterioration, world.player.morale])
	system_map.set("player_audio_visualizer_unlocked", (world.player.unlocked_upgrades.find(world.player.UPGRADE_ID.AUDIO_VISUALIZER) != -1))
	system_map.set("player_gas_layer_surveyor_unlocked", (world.player.unlocked_upgrades.find(world.player.UPGRADE_ID.GAS_LAYER_SURVEYOR) != -1))
	system_3d.set("player_position", world.player.position)
	long_range_scopes.set("player_position", world.player.position)
	barycenter_visualizer.set("_player_position", world.player.position)
	audio_visualizer.set("saved_audio_profiles_size_matrix", [world.player.saved_audio_profiles.size(), world.player.max_saved_audio_profiles])
	audio_visualizer.set("saved_audio_profiles", world.player.saved_audio_profiles)
	dialogue_manager.set("player", world.player)
	lrs_bestiary.set("discovered_entities_matrix", world.player.discovered_entities)
	gas_layer_surveyor.set("_discovered_gas_layers_matrix", world.player.discovered_gas_layers)
	
	audio_handler.enable_music_criteria["audio_visualizer_not_visible"] = !$audio_visualizer_window.is_visible()
	audio_handler.enable_music_criteria["countdown_processor_not_active"] = !countdown_processor != null
	
	game_data.player_weirdness_index = world.player.weirdness_index #really hacky solution which should not have been done this way but im too tired to change the entire game now to accomodate it.
	
	if Input.is_action_just_pressed("SC_PAUSE"):
		_on_open_pause_menu() #since game.gd is unpaused only, the pause menu can only open when the game is unpaused
	if Input.is_action_just_pressed("SC_DEBUG_MISC"):
		dialogue_manager.clear_and_load_rules()
	if Input.is_action_just_pressed("SC_DEBUG_MISC2"):
		var new_query = responseQuery.new()
		new_query.add("concept", "DEBUG_printTest")
		get_tree().call_group("dialogueManager", "speak", self, new_query)
	
	#DEBUG \/\//\/\/\//\/\\/
	#if Input.is_action_just_pressed("SC_DEBUG_MISC"):
		#var new_query = responseQuery.new()
		#new_query.add("concept", "DEBUGfalseMatchTest")
		#get_tree().call_group("dialogueManager", "speak", self, new_query)
	
	#ultra miscellanious:
	_on_update_countdown_overlay_shown(countdown_processor != null)
	pass

func _on_player_theorised_body(theorised_body: bodyAPI):
	var new_query = responseQuery.new()
	new_query.add("concept", "theorisedBody")
	body_query_add_shared(new_query, theorised_body)
	
	#type construction >>>>>>>
	match theorised_body.get_type():
		starSystemAPI.BODY_TYPES.CUSTOM:
			if not theorised_body.get_dialogue_tag().is_empty():
				body_query_add_custom_type_shared(new_query, theorised_body)
	
	get_tree().call_group("dialogueManager", "speak", self, new_query)
	
	#type response >>>>>>>
	match theorised_body.get_type():
		_:
			pass
	pass

func _on_player_orbiting_body(orbiting_body: bodyAPI):
	var new_query = responseQuery.new()
	new_query.add("concept", "orbitingBody")
	body_query_add_shared(new_query, orbiting_body)
	
	#type construction >>>>>>>
	match orbiting_body.get_type():
		starSystemAPI.BODY_TYPES.CUSTOM:
			if not orbiting_body.get_dialogue_tag().is_empty():
				body_query_add_custom_type_shared(new_query, orbiting_body)
				new_query.add("custom_orbit_available", orbiting_body.metadata.get("custom_orbit_available", true))
	
	get_tree().call_group("dialogueManager", "speak", self, new_query)
	var RETURN_STATE = await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
	
	#type response >>>>>>>
	match orbiting_body.get_type():
		starSystemAPI.BODY_TYPES.CUSTOM:
			match RETURN_STATE:
				"HARD_LEAVE":
					orbiting_body.metadata["custom_available"] = false
					orbiting_body.metadata["custom_orbit_available"] = false
	pass

func _on_player_following_body(following_body: bodyAPI):
	var new_query = responseQuery.new()
	new_query.add("concept", "followingBody")
	body_query_add_shared(new_query, following_body)
	
	#type construction >>>>>>>
	match following_body.get_type():
		starSystemAPI.BODY_TYPES.CUSTOM:
			if not following_body.get_dialogue_tag().is_empty():
				body_query_add_custom_type_shared(new_query, following_body)
				new_query.add("custom_follow_available", following_body.metadata.get("custom_follow_available", true))
		starSystemAPI.BODY_TYPES.WORMHOLE:
			new_query.add_tree_access("wormhole_disabled", following_body.is_disabled())
			new_query.add_tree_access("pending_audio_profiles", world.get_pending_audio_profiles().size() > 0) #for AV FLAIR
		starSystemAPI.BODY_TYPES.STATION:
			var station_abandoned: bool = following_body.station_classification in [game_data.STATION_CLASSIFICATIONS.ABANDONED, game_data.STATION_CLASSIFICATIONS.ABANDONED_BACKROOMS, game_data.STATION_CLASSIFICATIONS.ABANDONED_OPERATIONAL, game_data.STATION_CLASSIFICATIONS.COVERUP, game_data.STATION_CLASSIFICATIONS.PARTIALLY_SALVAGED]
			var station_inhabited: bool = following_body.station_classification in [game_data.STATION_CLASSIFICATIONS.STANDARD, game_data.STATION_CLASSIFICATIONS.PIRATE]
			new_query.add("station_available", following_body.metadata.get("station_available", true))
			new_query.add_tree_access("station_classification", str(game_data.STATION_CLASSIFICATIONS.find_key(following_body.station_classification)))
			new_query.add_tree_access("station_abandoned", station_abandoned)
			new_query.add_tree_access("station_inhabited", station_inhabited)
		starSystemAPI.BODY_TYPES.PLANET:
			new_query.add("planetary_anomaly", following_body.metadata.get("planetary_anomaly", false))
			new_query.add("planetary_anomaly_available", following_body.metadata.get("planetary_anomaly_available", false))
			new_query.add_tree_access("planet_classification", following_body.metadata.get("planet_classification"))
			new_query.add_tree_access("planet_type", following_body.metadata.get("planet_type"))
			new_query.add_tree_access("missing_AO", following_body.metadata.get("missing_AO", false))
			new_query.add_tree_access("missing_GL", following_body.metadata.get("missing_GL", false))
			new_query.add_tree_access("seed", following_body.metadata.get("seed", 0))
		starSystemAPI.BODY_TYPES.SPACE_ANOMALY:
			new_query.add("space_anomaly_available", following_body.metadata.get("space_anomaly_available", true))
			new_query.add_tree_access("seed", following_body.metadata.get("seed", 0))
		starSystemAPI.BODY_TYPES.SPACE_ENTITY:
			new_query.add_tree_access("space_entity_type", str(game_data.ENTITY_CLASSIFICATIONS.find_key(following_body.entity_classification)))
		starSystemAPI.BODY_TYPES.STAR:
			new_query.add_tree_access("star_type", following_body.metadata.get("star_type"))
	
	get_tree().call_group("dialogueManager", "speak", self, new_query)
	var RETURN_STATE = await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
	
	#type response >>>>>>>
	match following_body.get_type():
		starSystemAPI.BODY_TYPES.CUSTOM:
			match RETURN_STATE:
				"HARD_LEAVE":
					following_body.metadata["custom_available"] = false
					following_body.metadata["custom_follow_available"] = false
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_body)
				_:
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_body)
		starSystemAPI.BODY_TYPES.WORMHOLE:
			match RETURN_STATE:
				"ENTER_WORMHOLE":
					var wormholes = world.player.current_star_system.get_wormholes()
					var destination = following_body.destination_system
					if (not destination == world.player.previous_star_system) and (not following_body.is_disabled()): # im a lil paranoid teeehee :3
						enter_wormhole(following_body, wormholes, destination)
				_:
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_body)
		starSystemAPI.BODY_TYPES.STATION:
			match RETURN_STATE:
				"DOCK_WITH_STATION":
					dock_with_station(following_body)
				"POST_SALVAGE_LEAVE": #this is for abandoned stations which yield salvage, which should not be repeatable
					following_body.metadata["station_available"] = false
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_body)
				_:
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_body)
		starSystemAPI.BODY_TYPES.PLANET:
			match RETURN_STATE:
				"HARD_LEAVE":
					following_body.metadata["planetary_anomaly_available"] = false
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_body)
				"SOFT_LEAVE":
					following_body.metadata["planetary_anomaly_available"] = true
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_body)
				"HARD_LEAVE_STATION_OVERRIDE": #for planetary settlements
					following_body.metadata["planetary_anomaly_available"] = false
					
					var temp_station: stationBodyAPI = stationBodyAPI.new()
					temp_station.set_display_name(game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.STATION, game_data.NAME_SCHEMES.STANDARD))
					temp_station.station_classification = game_data.STATION_CLASSIFICATIONS.PIRATE
					var random = RandomNumberGenerator.new()
					random.set_seed(following_body.metadata.get("seed", randi()))
					temp_station.sell_percentage_of_market_price = random.randi_range(25,75)
					dock_with_station(temp_station)
				_:
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_body)
		starSystemAPI.BODY_TYPES.SPACE_ANOMALY:
			match RETURN_STATE:
				"HARD_LEAVE":
					following_body.metadata["space_anomaly_available"] = false
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_body)
				"SOFT_LEAVE":
					following_body.metadata["space_anomaly_available"] = true
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_body)
				"HARD_LEAVE_STATION_OVERRIDE": #for outposts
					following_body.metadata["space_anomaly_available"] = false
					
					var temp_station: stationBodyAPI = stationBodyAPI.new()
					temp_station.set_display_name(game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.STATION, game_data.NAME_SCHEMES.STANDARD))
					temp_station.station_classification = game_data.STATION_CLASSIFICATIONS.PIRATE
					var random = RandomNumberGenerator.new()
					random.set_seed(following_body.metadata.get("seed", randi()))
					temp_station.sell_percentage_of_market_price = random.randi_range(25,75)
					dock_with_station(temp_station)
				_:
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_body)
		_:
			_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_body)
	pass

func body_query_add_shared(query: responseQuery, body: bodyAPI) -> void:
	query.add("type", starSystemAPI.BODY_TYPES.find_key(body.get_type()))
	query.add_tree_access("name", body.get_display_name())
	query.add("tutorial", init_type == global_data.GAME_INIT_TYPES.TUTORIAL)
	pass

func body_query_add_custom_type_shared(query: responseQuery, body: bodyAPI) -> void: #shared between theorisedBody, orbitingBody, followingBody
	query.add("custom_tag", body.get_dialogue_tag())
	query.add("custom_available", body.metadata.get("custom_available", true))
	query.add_tree_access("seed", body.metadata.get("seed", 0))
	pass

func _on_async_upgrade_tutorial(upgrade_idx: playerAPI.UPGRADE_ID):
	match upgrade_idx:
		playerAPI.UPGRADE_ID.AUDIO_VISUALIZER:
			var new_query = responseQuery.new()
			new_query.add("concept", "moduleTutorial")
			new_query.add("module", "audioVisualizer")
			new_query.add_tree_access("m_upper", "Audio Visualizer")
			get_tree().call_group("dialogueManager", "speak", self, new_query)
			
		playerAPI.UPGRADE_ID.NANITE_CONTROLLER:
			var new_query = responseQuery.new()
			new_query.add("concept", "moduleTutorial")
			new_query.add("module", "naniteController")
			new_query.add_tree_access("m_upper", "Nanite Controller")
			get_tree().call_group("dialogueManager", "speak", self, new_query)
			
		playerAPI.UPGRADE_ID.LONG_RANGE_SCOPES:
			var new_query = responseQuery.new()
			new_query.add("concept", "moduleTutorial")
			new_query.add("module", "longRangeScopes")
			new_query.add_tree_access("m_upper", "Long Range Scopes")
			get_tree().call_group("dialogueManager", "speak", self, new_query)
	pass


func enter_wormhole(following_wormhole, wormholes, destination: starSystemAPI):
	#spawning new wormholes in destination system if nonexistent
	if not destination.destination_systems:
		for i in range(2):
			_on_create_new_star_system(destination)
	#setting whether the new system is a civilized system or not
	world.player.removeJumpsRemaining(1) #removing jumps remaining until reaching a civilized system
	if world.player.get_jumps_remaining() == 0:
		world.player.resetJumpsRemaining()
		destination.createAuxiliaryCivilized()
	else:
		destination.createAuxiliaryUnexplored()
	
	
	var destination_wormhole: wormholeBodyAPI = destination.get_wormhole_with_destination_system(world.player.current_star_system)
	destination_wormhole.known = true
	
	
	#removing other possible systems to traverse from previous system
	for w in wormholes:
		if w != following_wormhole: #if the wormhole is not the current wormhole being traversed
			if w.destination_system:
				if w.destination_system != world.player.previous_star_system:
					world.removeStarSystem(w.destination_system.get_identifier())
	
	#removing all other systems when leaving a civilized system (need to know about all the systems when in a civilized system in case i want to add the ability to look over exploration data while at a station)
	if world.player.current_star_system.is_civilized():
		var exclude_systems = destination.destination_systems.duplicate()
		exclude_systems.append(destination)
		world.remove_systems_excluding_systems(exclude_systems)
	
	world.player.previous_star_system = world.player.current_star_system
	world.player.systems_traversed += 1
	
	if world.player.systems_traversed == world.player.total_systems: # will need a global variable for how many ssystems until win at some point, customizability would be sick
		_on_player_win()
	
	#setting position to wormhole??? actually works??????
	_on_update_player_action_type(playerAPI.ACTION_TYPES.NONE, null)
	for body in destination.bodies:
		destination.updateBodyPosition(body.get_identifier(), get_physics_process_delta_time())
	world.player.position = destination_wormhole.position
	world.player.setTargetPosition(world.player.position)
	world.player.updatePosition(get_physics_process_delta_time())
	
	system_map._on_clear_console_entries()
	_on_switch_star_system(destination)
	barycenter_visualizer.locked_body_identifier = 0
	
	#removed from the late _on_movement_lock_timer_start function - probably does nothing but im too scared to not add it here just in case
	system_map.follow_body = null
	system_map.locked_body = null
	system_map.action_body = null
	
	wormhole_minigame.initialize(world.player.weirdness_index, world.player.hull_stress_wormhole)
	_on_wormhole_minigame_popup()
	_on_player_entering_system(destination) #this dialogue is overwritten if the player dies during traversal!
	pass

func dock_with_station(following_station):
	station_ui.station = following_station
	station_ui.player_current_value = world.player.current_value
	station_ui.player_balance = world.player.balance
	station_ui.player_hull_stress = world.player.hull_stress
	station_ui.set("player_saved_audio_profiles_size_matrix", [world.player.saved_audio_profiles.size(), world.player.max_saved_audio_profiles])
	station_ui.set("pending_audio_profiles", world.get_pending_audio_profiles())
	_on_station_popup()
	pass


func _on_player_death():
	await pause_mode_handler.pauseModeNone
	print("GAME: PLAYER DIED")
	
	var new_query = responseQuery.new()
	new_query.add("concept", "playerDeath")
	get_tree().call_group("dialogueManager", "speak", self, new_query)
	
	await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
	
	_on_open_stats_menu(stats_menu.INIT_TYPES.DEATH)
	pass

func _on_player_win():
	print("GAME: PLAYER WON")
	
	var new_query = responseQuery.new()
	new_query.add("concept", "playerWin")
	get_tree().call_group("dialogueManager", "speak", self, new_query)
	
	await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
	
	_on_open_stats_menu(stats_menu.INIT_TYPES.WIN)
	pass

func _on_player_entering_system(system: starSystemAPI):
	#only called when entering a system for the first time, not for loading the system
	#called by enter_wormhole - SHOULD await the wormhole minigame closing before starting because of pause modes
	var new_query = responseQuery.new()
	new_query.add("concept", "enteringSystem")
	#new_query.add_tree_access("name", system.get_display_name()) # no point to do this as the system display name will always be 'random' or 'tutorial' or whatever!
	new_query.add_tree_access("special_system_classification", str(game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.find_key(system.special_system_classification)))
	new_query.add_tree_access("system_hazard_classification", str(game_data.SYSTEM_HAZARD_CLASSIFICATIONS.find_key(system.system_hazard_classification)))
	new_query.add_tree_access("system_star_type", system.get_first_star().metadata.get("star_type"))
	get_tree().call_group("dialogueManager", "speak", self, new_query)
	
	#not awaiting onCloseDialog because wacky shtuff happens!!!!!!! audioHandler should only play it when pause_mode is NONE anyway
	
	if system.is_civilized():
		get_tree().call_group("audioHandler", "queue_music", "res://Sound/Music/motif.tres")
	pass

func _on_player_mutiny() -> void:
	await pause_mode_handler.pauseModeNone
	print("GAME: PLAYER MUTINY")
	
	var new_query = responseQuery.new()
	new_query.add("concept", "playerMutiny")
	get_tree().call_group("dialogueManager", "speak", self, new_query)
	
	var RETURN_STATE = await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
	match RETURN_STATE:
		"HARD_LEAVE":
			_on_player_death()
		"SOFT_LEAVE":
			pass
		_:
			pass
	pass



func _on_update_player_action_type(type: playerAPI.ACTION_TYPES, action_body):
	if not (type == world.player.current_action_type and action_body == world.player.action_body):
		long_range_scopes._on_current_entity_cleared()
		gas_layer_surveyor._on_current_planet_cleared()
	
	world.player.current_action_type = type
	if action_body != null:
		world.player.pending_action_body = action_body
	pass

func _on_update_player_target_position(pos: Vector2):
	world.player.target_position = pos
	print("SYSTEM MAP: UPDATING PLAYER TARGET POSITION: ", pos)
	pass

func _on_update_target_position(pos: Vector2):
	system_3d.set("target_position", pos)
	print("SYSTEM MAP: UPDATING TARGET POSITION: ", pos)
	pass

func _on_create_new_star_system(for_system: starSystemAPI = null):
	game_data.SYSTEM_PREFIX = "" #shuldnt be calling game_data from game.gd but whateverrrrrrr
	var system = world.createStarSystem("random")
	system.createBase(world.PA_chance_per_planet, world.missing_AO_chance_per_planet, world.SA_chance_per_candidate, world.missing_GL_chance_per_relevant_planet)
	if for_system != null:
		for_system.destination_systems.append(system)
		system.previous_system = for_system
	print("GAME (DEBUG): CREATING NEW STAR SYSTEM")
	return system

func _on_switch_star_system(to_system: starSystemAPI):
	print_debug("GAME (DEBUG) SWITCHING STAR SYSTEM")
	#if world.player.current_star_system:
		#if world.player.current_star_system.bodies.find(audio_visualizer.current_audio_profile) != -1: #this was the thing throwing TypedArray does not inherit from GDScript errors, so I just removed it.... hopefully ok. does not look important at all
	audio_visualizer._on_clear_button_pressed()
	
	world.player.current_star_system = to_system
	system_map.system = to_system
	system_3d.system = to_system
	barycenter_visualizer.system = to_system
	long_range_scopes.system = to_system
	dialogue_manager.system = to_system
	
	system_3d.spawnBodies()
	system_3d.reset_locked_body()
	journey_map.add_new_system(world.player.systems_traversed)
	journey_map.jumps_remaining = world.player.get_jumps_remaining() #required as it needs to update when the players system on game startup is loaded, not just wormhole traversal!
	_on_process_system_hazard(to_system)
	return to_system

func _on_process_system_hazard(system: starSystemAPI):
	#clear prior system hazard utility
	if countdown_processor != null:
		countdown_processor.queue_free()
	#process new hazard
	var hazard = system.system_hazard_classification
	var metadata = system.system_hazard_metadata
	match hazard:
		game_data.SYSTEM_HAZARD_CLASSIFICATIONS.CORONAL_MASS_EJECTION:
			
			var time_random = clamp(randfn(120, 30) - (game_data.player_weirdness_index * 30.0), 30.0, 240.0)
			var time_total = metadata.get_or_add("CME_time_total", time_random)
			var time_current = metadata.get_or_add("CME_time_current", time_total)
			var processor = load("res://Scenes/Countdown Processor/countdown_processor.tscn")
			var CDP = processor.instantiate()
			add_child(CDP)
			countdown_processor = CDP
			CDP.updateCountdownOverlay.connect(_on_update_countdown_overlay_info) # display
			CDP.countdownTick.connect(_on_update_countdown_overlay_time.unbind(1)) # display
			CDP.countdownTick.connect(_on_CME_time_current_updated) # real
			CDP.countdownTimeout.connect(_on_CME_timeout) # real
			CDP.initialize(system.get_identifier(), "WARNING", "CORONAL MASS EJECTION", world.player.hull_stress_CME, time_total, time_current)
			
		game_data.SYSTEM_HAZARD_CLASSIFICATIONS.NONE:
			pass
	pass

func _on_locked_body_updated(body: bodyAPI):
	system_3d.set("locked_body_identifier", body.get_identifier())
	system_3d.set("label_locked_body_identifier", body.get_identifier())
	system_3d.set("target_position", Vector2.ZERO)
	barycenter_visualizer.set("locked_body_identifier", body.get_identifier())
	audio_visualizer._on_locked_body_updated(body)
	pass

func _on_locked_body_depreciated():
	system_3d.set("label_locked_body_identifier", 0)
	pass

func _on_found_body(id: int):
	var system: starSystemAPI = world.get_system_from_identifier(world.player.current_star_system.get_identifier())
	if system:
		var body = system.get_body_from_identifier(id)
		if body:
			body.known = true
			if body.metadata.has("value"): world.player.current_value += (body.metadata.get("value") * system.get_first_star_discovery_multiplier())
			system_map._on_found_body(id)
			var sub_bodies = system.get_bodies_with_hook_identifier(id)
			if sub_bodies:
				for sub_body in sub_bodies:
					if sub_body.get_type() == starSystemAPI.BODY_TYPES.ASTEROID_BELT:
						sub_body.known = true
	pass

func _on_add_console_entry(entry_text: String, text_color: Color = Color.WHITE): #called via systtem 3d
	print_debug("ADD CONSOLE ITEM CALLED ", entry_text, " ", text_color)
	system_map._on_add_console_entry(entry_text, text_color)
	pass

func _on_sonar_ping(ping_width: int, ping_length: int, ping_direction: Vector2):
	print("GAME (DEBUG): PINGING")
	system_map._on_sonar_ping(ping_width, ping_length, ping_direction)
	pass

func _on_sonar_values_changed(ping_width: int, ping_length: int, ping_direction: Vector2):
	system_map._on_sonar_values_changed(ping_width, ping_length, ping_direction)
	barycenter_visualizer._ping_length = ping_length
	barycenter_visualizer._ping_direction = ping_direction
	pass

func _on_sell_exploration_data(sell_percentage_of_market_price: int):
	print("STATION_UI (DEBUG): SELLING EXPLORATION DATA")
	var multiplier = sell_percentage_of_market_price / 100.0
	var sell_for = world.player.current_value * multiplier #star system multiplier is already added to value
	
	#dont worry, audio profiles are added by observed_bodies_list.gd when opened, and are added to player current value - i dont know what that means either, go find out yourself idk idk idk
	
	world.player.increaseBalance(sell_for)
	world.player.current_value = 0
	station_ui.player_balance = world.player.balance
	pass

func _on_upgrade_ship(upgrade_idx: playerAPI.UPGRADE_ID, cost: int):
	print("STATION_UI (DEBUG): UPGRADING SHIP")
	if world.player.balance >= cost and (world.player.get_upgrade_unlocked_state(upgrade_idx) != true):
		world.player.decreaseBalance(cost)
		_on_unlock_upgrade(upgrade_idx)
		station_ui._on_disable_module_store() #i really dont know..... shouldnt do anything if not at a station because of 'if station' keywords in thingi fubhodgifaphjdlghruoetaifjpdvghruaeofisdh
	station_ui.player_balance = world.player.balance
	pass

func _on_unlock_upgrade(upgrade_idx: playerAPI.UPGRADE_ID):
	var unlock = world.player.unlockUpgrade(upgrade_idx)
	_on_upgrade_state_change(unlock, true)
	pass

func _on_lock_upgrade(upgrade_idx: playerAPI.UPGRADE_ID):
	var lock = world.player.lockUpgrade(upgrade_idx)
	_on_upgrade_state_change(lock, false)
	pass

func _on_upgrade_state_change(upgrade_idx: playerAPI.UPGRADE_ID, state: bool):
	print("GAME (DEBUG): UPGRADE STATE CHANGED: ", upgrade_idx, " ", state)
	get_tree().call_group("FOLLOW_UPGRADE_STATE", "_on_upgrade_state_change", upgrade_idx, state)
	if state == true and pause_mode_handler.pause_mode == game_data.PAUSE_MODES.STATION_UI:
		_on_async_upgrade_tutorial(upgrade_idx)
	pass

func _on_remove_saved_audio_profile(helper: audioProfileHelper):
	world.player.removeAudioProfile(helper)
	pass

func _on_add_saved_audio_profile(helper: audioProfileHelper):
	world.player.addAudioProfile(helper)
	station_ui.set("player_saved_audio_profiles_size_matrix", [world.player.saved_audio_profiles.size(), world.player.max_saved_audio_profiles])
	pass

func _on_decrease_player_balance(amount: int) -> void:
	world.player.decreaseBalance(amount)
	pass

func _on_add_player_value(amount: int) -> void:
	world.player.current_value += amount
	pass

func _on_add_player_hull_stress(amount: int) -> void:
	#damage sfx, couldnt find any other place to put this :(
	if amount > 0:
		if world.player.hull_stress >= 100:
			get_tree().call_group("audioHandler", "play_once", load("res://Sound/SFX/damage_deterioration.tres"), -12, "SFX")
		else:
			get_tree().call_group("audioHandler", "play_once", load("res://Sound/SFX/damage_stress.tres"), -12, "SFX")
	world.player.addHullStress(amount)
	pass

func _on_remove_player_hull_stress(amount: int) -> void:
	world.player.removeHullStress(amount)
	pass

func _on_player_hull_deterioration_changed(new_value: int) -> void:
	if new_value == 100:
		_on_player_death()
	pass

func _on_player_morale_changed(new_value: int) -> void:
	if new_value == 0:
		_on_player_mutiny()
	pass

func _on_kill_character_with_occupation(occupation: characterAPI.OCCUPATIONS) -> void:
	var character = world.player.get_character_with_occupation(occupation)
	if character:
		character.kill()
	pass

func _on_update_player_is_boosting(is_boosting: bool):
	world.player.boosting = is_boosting
	pass

func _on_remove_hull_stress_for_nanites(amount: int, nanites_per_percentage: int) -> void: #both station ui and system map
	if (world.player.balance >= amount * nanites_per_percentage) and (world.player.hull_stress > 0):
		world.player.decreaseBalance(amount * nanites_per_percentage)
		_on_remove_player_hull_stress(amount)
		print_debug("REMOVE HULL STRESS SUCCESSFUL")
	station_ui.player_balance = world.player.balance
	station_ui.player_hull_stress = world.player.hull_stress
	pass

func _on_add_dialogue_memory_pair(key, value):
	world.dialogue_memory[key] = value
	dialogue_manager.dialogue_memory = world.dialogue_memory
	pass

func _on_open_pause_menu():
	pause_mode_handler._on_queue_pause_mode(game_data.PAUSE_MODES.PAUSE_MENU)
	pass

func _on_open_stats_menu(_init_type: int): #init type is from statsMenu INIT_TYPES
	stats_menu.init_type = _init_type
	stats_menu._player_score = world.player.total_score
	pause_mode_handler._on_queue_pause_mode(game_data.PAUSE_MODES.STATS_MENU)
	pass

func _on_save_world():
	game_data.saveWorld(world)
	pass

func _on_save_and_quit():
	game_data.saveWorld(world)
	global_data.change_scene.emit("res://Scenes/Main Menu/main_menu.tscn")
	pass

func _on_exit_to_main_menu():
	global_data.change_scene.emit("res://Scenes/Main Menu/main_menu.tscn")
	pass

func _on_theorised_body(id: int):
	var body = world.player.current_star_system.get_body_from_identifier(id)
	if body: 
		_on_player_theorised_body(body)
	pass

func _on_tutorial_set_ingress_override(value: bool):
	barycenter_visualizer.TUTORIAL_INGRESS_OVERRIDE = value
	system_3d.TUTORIAL_INGRESS_OVERRIDE = value
	system_map.TUTORIAL_INGRESS_OVERRIDE = value
	pass

func _on_tutorial_set_omission_override(value: bool):
	barycenter_visualizer.TUTORIAL_OMISSION_OVERRIDE = value
	system_3d.TUTORIAL_OMISSION_OVERRIDE = value
	system_map.TUTORIAL_OMISSION_OVERRIDE = value
	pass

func _on_tutorial_player_win():
	_on_open_stats_menu(stats_menu.INIT_TYPES.TUTORIAL)
	pass

func _on_add_player_morale(amount : int) -> void:
	world.player.addMorale(amount)
	pass

func _on_remove_player_morale(amount : int) -> void:
	world.player.removeMorale(amount)
	pass

func _on_stats_menu_quit(_init_type: int) -> void:
	match _init_type:
		stats_menu.INIT_TYPES.TUTORIAL:
			global_data.change_scene.emit("res://Scenes/Main Menu/main_menu.tscn")
		_:
			global_data.change_scene.emit("res://Scenes/Main Menu/main_menu.tscn") #WIN, DEATH
			game_data.deleteWorld()
	pass

func _on_player_data_value_changed(new_value: int):
	system_map._on_player_data_value_changed(new_value)
	pass

func _on_add_player_mutiny_backing(amount : int) -> void:
	world.player.addMutinyBacking(amount)
	pass

func _on_CME_time_current_updated(_time_current: float, _system_id: int):
	world.get_system_from_identifier(_system_id).system_hazard_metadata["CME_time_current"] = _time_current
	if _time_current <= 10:
		get_tree().call_group("audioHandler", "play_once", load("res://Sound/SFX/tick_high.wav"), -24, "SFX")
	else:
		get_tree().call_group("audioHandler", "play_once", load("res://Sound/SFX/tick_low.wav"), -24, "SFX")
	pass

func _on_CME_timeout(_system_id: int):
	#_system_id is appended here incase you want to physically change something in system as an effect or soemthing
	world.player.CME_immune = false
	system_map._on_CME_timeout(_system_id)
	#call countdown overlay for special effects - has to be in this function as the effects are CME specific so it shouldnt be a general coutndown overlay thing!
	pass

func _on_player_below_CME_ring_radius():
	if not world.player.CME_immune:
		world.player.CME_immune = true
		
		_on_add_player_hull_stress(world.player.hull_stress_CME)
		get_tree().call_group("audioHandler", "play_once", load("res://Sound/SFX/coronal_mass_ejection.wav"), 0.0, "SFX")
		system_map._on_countdown_overlay_CME_flash()
	pass

func _on_update_countdown_overlay_info(_title: String, _description: String, _hull_stress: int):
	system_map._on_update_countdown_overlay_info(_title, _description, _hull_stress)
	pass

func _on_update_countdown_overlay_time(_time: float):
	system_map._on_update_countdown_overlay_time(_time)
	#tick sound is played in system map
	pass

func _on_update_countdown_overlay_shown(_shown: bool):
	system_map._on_update_countdown_overlay_shown(_shown)
	pass

func _on_update_player_in_asteroid_belt(player_in_asteroid_belt: bool):
	world.player.in_asteroid_belt = player_in_asteroid_belt
	pass

func _on_player_action_type_pending_or_completed(type: playerAPI.ACTION_TYPES, body: bodyAPI, pending: bool):
	#funny how this is the ONLY use case so far...
	system_map._on_update_current_action_display(type, body, pending)
	pass

func _on_active_objectives_changed(_active_objectives: Array[objectiveAPI]) -> void:
	world.active_objectives.clear()
	world.active_objectives = _active_objectives.duplicate(true)
	system_map._on_active_objectives_changed(_active_objectives)
	pass

func _on_update_objectives_panel(_active_objectives: Array[objectiveAPI]) -> void:
	pause_menu._on_update_objectives_panel(_active_objectives)
	pass

func _on_open_LRS():
	var following_body = system_map.follow_body
	if world.player.get_upgrade_unlocked_state(world.player.UPGRADE_ID.LONG_RANGE_SCOPES) == true:
		long_range_scopes._on_current_entity_changed(following_body)
		lrs_bestiary._on_current_entity_changed(following_body)
		if world.player.discovered_entities.find(following_body.entity_classification) == -1:
			world.player.discovered_entities.append(following_body.entity_classification)
		if not $long_range_scopes_window.is_visible():
			_on_long_range_scopes_popup()
	pass

func _on_open_GLS():
	var following_body = system_map.follow_body
	if world.player.get_upgrade_unlocked_state(world.player.UPGRADE_ID.GAS_LAYER_SURVEYOR) == true:
		gas_layer_surveyor._on_current_planet_changed(following_body)
		for tag in gas_layer_surveyor.current_layers:
			var idx = gas_layer_surveyor.layer_data.keys().find(tag)
			if world.player.discovered_gas_layers.find(idx) == -1:
				world.player.discovered_gas_layers.append(idx)
		if not $gas_layer_surveyor_window.is_visible():
			_on_gas_layer_surveyor_popup()
	pass




#the epic handshake between game.gd and pauseModeHandler.gd
func _on_queue_pause_mode(new_mode: game_data.PAUSE_MODES) -> void:
	pause_mode_handler._on_queue_pause_mode(new_mode)
	pass

func _on_set_pause_mode(new_mode: game_data.PAUSE_MODES) -> void:
	pause_mode_handler._on_set_pause_mode(new_mode)
	pass

func _on_pause_mode_changed(new_mode: game_data.PAUSE_MODES) -> void:
	stats_menu._pause_mode = new_mode
	pause_menu._pause_mode = new_mode
	dialogue_manager._pause_mode = new_mode
	station_ui._pause_mode = new_mode
	wormhole_minigame._pause_mode = new_mode
	audio_handler._pause_mode = new_mode #audio handler doesnt TECHNICALLY need pause control
	system_map._pause_mode = new_mode #for hiding when in dialogue
	objectives_manager._pause_mode = new_mode
	
	system_map.reset_player_boosting() #to stop boosting from being stuck to true, this SHOULD cover ALL grounds!
	system_map.reset_actions_buttons_pressed() #godot 4.3 migration quick fix
	pass



func _ON_DEBUG_REVEAL_ALL_WORMHOLES():
	for body in world.player.current_star_system.bodies:
		if body.get_type() == starSystemAPI.BODY_TYPES.WORMHOLE:
			body.known = true
	pass

func _ON_DEBUG_REVEAL_ALL_BODIES():
	for body in world.player.current_star_system.bodies:
		body.known = true
	pass

func _ON_DEBUG_QUICK_ADD_NANITES():
	world.player.increaseBalance(100000)
	pass







func _on_audio_visualizer_popup():
	audio_visualizer._on_popup()
	if $audio_visualizer_window.is_visible():
		$audio_visualizer_window.hide()
	else:
		$audio_visualizer_window.move_to_center()
		$audio_visualizer_window.popup()
		_on_add_console_entry("Opening audio visualizer.", Color("353535"))
	pass

func _on_station_popup():
	pause_mode_handler._on_queue_pause_mode(game_data.PAUSE_MODES.STATION_UI)
	pass

func _on_wormhole_minigame_popup():
	pause_mode_handler._on_queue_pause_mode(game_data.PAUSE_MODES.WORMHOLE_MINIGAME)
	pass

func _on_journey_map_popup():
	if $journey_map_window.is_visible():
		$journey_map_window.hide()
	else:
		$journey_map_window.move_to_center()
		$journey_map_window.popup()
		_on_add_console_entry("Opening journey map.", Color("353535"))
	pass

func _on_long_range_scopes_popup():
	if $long_range_scopes_window.is_visible():
		$long_range_scopes_window.hide()
	else:
		$long_range_scopes_window.move_to_center()
		$long_range_scopes_window.popup()
		_on_add_console_entry("Opening long range scopes.", Color("353535"))
	pass

func _on_gas_layer_surveyor_popup():
	if $gas_layer_surveyor_window.is_visible():
		$gas_layer_surveyor_window.hide()
	else:
		$gas_layer_surveyor_window.move_to_center()
		$gas_layer_surveyor_window.popup()
		_on_add_console_entry("Opening gas layer surveyor.", Color("353535"))
	pass
