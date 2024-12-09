extends Node
#Handles most game stuff that is not local to child windows, loads data, saves data, the whole thing. child windows must route data through this to change the world/system/player

var init_type: int = 0 #from global data GAME_INIT_TYPES
var init_data: Dictionary = {}
var world: worldAPI

@onready var system_map = $system_window/system
@onready var system_3d = $system_window/system/camera/canvas/control/scopes_snap_scroll/scopes_bg/scopes_margin/scopes_container/system_3d_window/system_3d
@onready var sonar = $system_window/system/camera/canvas/control/scopes_snap_scroll/core_panel_bg/core_panel_scroll/core_panel/core_margin/core_scroll/sonar_container/sonar_window/sonar_control
@onready var barycenter_visualizer = $system_window/system/camera/canvas/control/scopes_snap_scroll/core_panel_bg/core_panel_scroll/core_panel/core_margin/core_scroll/barycenter_container/barycenter_visualizer_window/barycenter_control
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


func _ready():
	system_map.connect("updatePlayerActionType", _on_update_player_action_type)
	system_map.connect("updatePlayerTargetPosition", _on_update_player_target_position)
	system_map.connect("updatePlayerIsBoosting", _on_update_player_is_boosting)
	system_map.connect("updateTargetPosition", _on_update_target_position)
	system_map.connect("updatedLockedBody", _on_locked_body_updated)
	system_map.connect("lockedBodyDepreciated", _on_locked_body_depreciated)
	system_map.connect("removeHullStressForNanites", _on_remove_hull_stress_for_nanites)
	system_map.connect("theorisedBody", _on_theorised_body)
	system_map.connect("DEBUG_REVEAL_ALL_WORMHOLES", _ON_DEBUG_REVEAL_ALL_WORMHOLES)
	system_map.connect("DEBUG_REVEAL_ALL_BODIES", _ON_DEBUG_REVEAL_ALL_BODIES)
	
	system_3d.connect("foundBody", _on_found_body)
	system_3d.connect("addConsoleItem", _on_add_console_item)
	
	sonar.connect("sonarPing", _on_sonar_ping)
	
	station_ui.connect("sellExplorationData", _on_sell_exploration_data)
	station_ui.connect("upgradeShip", _on_upgrade_ship)
	station_ui.connect("addSavedAudioProfile", _on_add_saved_audio_profile)
	station_ui.connect("removeHullStressForNanites", _on_remove_hull_stress_for_nanites)
	station_ui.connect("addPlayerValue", _on_add_player_value)
	
	audio_visualizer.connect("removeSavedAudioProfile", _on_remove_saved_audio_profile)
	
	long_range_scopes.connect("addConsoleItem", _on_add_console_item)
	long_range_scopes.connect("addPlayerValue", _on_add_player_value)
	
	system_map.connect("audioVisualizerPopup", _on_audio_visualizer_popup)
	system_map.connect("journeyMapPopup", _on_journey_map_popup)
	system_map.connect("longRangeScopesPopup", _on_long_range_scopes_popup)
	
	dialogue_manager.connect("addPlayerValue", _on_add_player_value)
	dialogue_manager.connect("addPlayerHullStress", _on_add_player_hull_stress)
	dialogue_manager.connect("removePlayerHullStress", _on_remove_player_hull_stress)
	dialogue_manager.connect("addPlayerMorale", _on_add_player_morale)
	dialogue_manager.connect("removePlayerMorale", _on_remove_player_morale)
	dialogue_manager.connect("killCharacterWithOccupation", _on_kill_character_with_occupation)
	dialogue_manager.connect("foundBody", _on_found_body)
	dialogue_manager.connect("TUTORIALSetIngressOverride", _on_tutorial_set_ingress_override)
	dialogue_manager.connect("TUTORIALSetOmissionOverride", _on_tutorial_set_omission_override)
	dialogue_manager.connect("TUTORIALPlayerWin", _on_tutorial_player_win)
	
	pause_menu.connect("saveWorld", _on_save_world)
	pause_menu.connect("saveAndQuit", _on_save_and_quit)
	pause_menu.connect("exitToMainMenu", _on_exit_to_main_menu)
	
	wormhole_minigame.connect("addPlayerHullStress", _on_add_player_hull_stress)
	
	
	pause_mode_handler.connect("pauseModeChanged", _on_pause_mode_changed)
	stats_menu.connect("queuePauseMode", _on_queue_pause_mode)
	pause_menu.connect("queuePauseMode", _on_queue_pause_mode)
	dialogue_manager.connect("queuePauseMode", _on_queue_pause_mode)
	station_ui.connect("queuePauseMode", _on_queue_pause_mode)
	wormhole_minigame.connect("queuePauseMode", _on_queue_pause_mode)
	stats_menu.connect("setPauseMode", _on_set_pause_mode)
	pause_menu.connect("setPauseMode", _on_set_pause_mode)
	dialogue_manager.connect("setPauseMode", _on_set_pause_mode)
	station_ui.connect("setPauseMode", _on_set_pause_mode)
	wormhole_minigame.connect("setPauseMode", _on_set_pause_mode)
	
	
	
	
	world = await game_data.loadWorld()
	if init_type == global_data.GAME_INIT_TYPES.TUTORIAL:
		world = game_data.createWorld(25, 5, 3, 10, 1, 0.01, 0.05, 0.25)
		
		dialogue_manager.dialogue_memory = world.dialogue_memory
		
		var new_player = world.createPlayer(
			init_data.get("name", "Tanaka"), 
			init_data.get("prefix", "Captain"))
		new_player.resetJumpsRemaining()
		
		# -> none of this should be necessary but im worried that the game will break if not included as queries might require this data
		new_player.first_officer = load("res://Data/Characters/rui.tres")
		new_player.chief_engineer = load("res://Data/Characters/jiya.tres")
		new_player.security_officer = load("res://Data/Characters/walker.tres")
		new_player.medical_officer = load("res://Data/Characters/febris.tres")
		for character in [new_player.first_officer, new_player.chief_engineer, new_player.security_officer, new_player.medical_officer, new_player.linguist, new_player.historian]:
			if character: dialogue_manager.character_lookup_dictionary[character.current_occupation] = character.display_name
		
		new_player.current_storyline = playerAPI.STORYLINES.keys().pick_random()
		# <-
		
		new_player.connect("orbitingBody", _on_player_orbiting_body)
		new_player.connect("followingBody", _on_player_following_body)
		new_player.connect("hullDeteriorationChanged", _on_player_hull_deterioration_changed)
		
		var new: starSystemAPI = load("res://Data/tutorial_system.tres")
		world.star_systems.append(new)
		
		world.player.systems_traversed = 12
		journey_map.generate_up_to_system(world.player.systems_traversed)
		
		_on_switch_star_system(new)
		
		_on_unlock_upgrade(playerAPI.UPGRADE_ID.ADVANCED_SCANNING)
		
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
		world = game_data.createWorld(25, 5, 3, 10, 1, 0.01, 0.05, 0.25)
		
		dialogue_manager.dialogue_memory = world.dialogue_memory
		
		var new_player = world.createPlayer(
			init_data.get("name", "Tanaka"), 
			init_data.get("prefix", "Captain"))
		new_player.resetJumpsRemaining()
		
		#CHARACTERS FOR ROGUELIKE:
		new_player.first_officer = load("res://Data/Characters/rui.tres")
		new_player.chief_engineer = load("res://Data/Characters/jiya.tres")
		new_player.security_officer = load("res://Data/Characters/walker.tres")
		new_player.medical_officer = load("res://Data/Characters/febris.tres")
		for character in [new_player.first_officer, new_player.chief_engineer, new_player.security_officer, new_player.medical_officer, new_player.linguist, new_player.historian]:
			if character: dialogue_manager.character_lookup_dictionary[character.current_occupation] = character.display_name
		
		new_player.current_storyline = playerAPI.STORYLINES.keys().pick_random()
		
		new_player.connect("orbitingBody", _on_player_orbiting_body)
		new_player.connect("followingBody", _on_player_following_body)
		new_player.connect("hullDeteriorationChanged", _on_player_hull_deterioration_changed)
		
		#new game stuff
		var new: starSystemAPI = _on_create_new_star_system(false)
		for i in range(2):
			_on_create_new_star_system(false, new)
		new.generateRandomWormholes()
		new.generateRandomWeightedStations()
		new.generateRandomWeightedEntities()
		new.generateRandomAnomalies(world.SA_chance_per_candidate)
		for body in new.bodies:
			body.is_known = true
		
		_on_switch_star_system(new)
		
		_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, new.get_first_star())
		#_on_unlock_upgrade(playerAPI.UPGRADE_ID.ADVANCED_SCANNING)
		#_on_unlock_upgrade(playerAPI.UPGRADE_ID.AUDIO_VISUALIZER)
		#_on_unlock_upgrade(playerAPI.UPGRADE_ID.LONG_RANGE_SCOPES)
		
		await get_tree().create_timer(1.0, true).timeout
		
		#var new_query = responseQuery.new()
		#new_query.add("concept", "openDialog")
		#new_query.add("id", "station")
		#new_query.add_tree_access("station_classification", str("ABANDONED"))
		#new_query.add_tree_access("is_station_abandoned", true)
		#new_query.add_tree_access("is_station_inhabited", false)
		#get_tree().call_group("dialogueManager", "speak", self, new_query)
		
		#_on_unlock_upgrade(playerAPI.UPGRADE_ID.ADVANCED_SCANNING)
		
		var new_query = responseQuery.new()
		new_query.add("concept", "playerStart")
		get_tree().call_group("dialogueManager", "speak", self, new_query)
		
		await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
		
		game_data.saveWorld(world) #so if the player leaves before saving, the save file does not go back to a previous game!
		
		#var debug = responseQuery.new()
		#debug.add("concept", "followingBody")
		#debug.add("id", "planetaryAnomaly")
		#debug.add_tree_access("planet_classification", "Terran")
		#debug.add_tree_access("player_in_ABYSS_region", true)
		#get_tree().call_group("dialogueManager", "speak", self, debug)
		
	
	elif init_type == global_data.GAME_INIT_TYPES.CONTINUE:
		
		dialogue_manager.dialogue_memory = world.dialogue_memory
		
		world.player.connect("orbitingBody", _on_player_orbiting_body)
		world.player.connect("followingBody", _on_player_following_body)
		world.player.connect("hullDeteriorationChanged", _on_player_hull_deterioration_changed)
		
		for i in world.player.current_star_system.destination_systems:
			i.previous_system = world.player.current_star_system #i call this 'turning the treadmill back on' - do not ask why.
		
		for upgrade in world.player.unlocked_upgrades:
			_on_upgrade_state_change(upgrade, true)
		
		journey_map.generate_up_to_system(world.player.systems_traversed)
		
		_on_switch_star_system(world.player.current_star_system)
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
	#if world.player.hull_deterioration == 100:
		#_on_player_death()
	
	#updating positions of everyhthing for windows
	system_map.set("player_position_matrix", [world.player.position, world.player.target_position])
	system_map.set("_player_status_matrix", [world.player.balance, world.player.hull_stress, world.player.hull_deterioration, world.player.morale])
	system_map.set("player_audio_visualizer_unlocked", (world.player.unlocked_upgrades.find(world.player.UPGRADE_ID.AUDIO_VISUALIZER) != -1))
	system_3d.set("player_position", world.player.position)
	long_range_scopes.set("player_position", world.player.position)
	audio_visualizer.set("saved_audio_profiles_size_matrix", [world.player.saved_audio_profiles.size(), world.player.max_saved_audio_profiles])
	audio_visualizer.set("saved_audio_profiles", world.player.saved_audio_profiles)
	dialogue_manager.set("player", world.player)
	lrs_bestiary.set("discovered_entities_matrix", world.player.discovered_entities)
	
	game_data.player_weirdness_index = world.player.weirdness_index #really hacky solution which should not have been done this way but im too tired to change the entire game now to accomodate it.
	
	if Input.is_action_just_pressed("pause"):
		_on_open_pause_menu() #since game.gd is unpaused only, the pause menu can only open when the game is unpaused
	pass

func _on_player_theorised_body(theorised_body: bodyAPI):
	if theorised_body.is_planet():
		if init_type == global_data.GAME_INIT_TYPES.TUTORIAL:
			var theorised_planet = theorised_body
			var new_query = responseQuery.new()
			new_query.add("concept", "theorisedBody")
			new_query.add("id", "planet")
			new_query.add_tree_access("name", theorised_planet.display_name)
			get_tree().call_group("dialogueManager", "speak", self, new_query)
	
	elif theorised_body is wormholeAPI:
		if init_type == global_data.GAME_INIT_TYPES.TUTORIAL:
			var theorised_wormhole = theorised_body
			var new_query = responseQuery.new()
			new_query.add("concept", "theorisedBody")
			new_query.add("id", "wormhole")
			new_query.add_tree_access("name", theorised_wormhole.display_name)
			get_tree().call_group("dialogueManager", "speak", self, new_query)
	pass

func _on_player_orbiting_body(orbiting_body: bodyAPI):
	if orbiting_body.is_planet():
		if init_type == global_data.GAME_INIT_TYPES.TUTORIAL:
			var orbiting_planet = orbiting_body
			var new_query = responseQuery.new()
			new_query.add("concept", "orbitingBody")
			new_query.add("id", "planet")
			new_query.add_tree_access("name", orbiting_planet.display_name)
			get_tree().call_group("dialogueManager", "speak", self, new_query)
	
	elif orbiting_body is wormholeAPI:
		if init_type == global_data.GAME_INIT_TYPES.TUTORIAL:
			var orbiting_wormhole = orbiting_body
			var new_query = responseQuery.new()
			new_query.add("concept", "orbitingBody")
			new_query.add("id", "wormhole")
			new_query.add_tree_access("name", orbiting_wormhole.display_name)
			get_tree().call_group("dialogueManager", "speak", self, new_query)
	pass

func _on_player_following_body(following_body: bodyAPI):
	if following_body is wormholeAPI:
		var following_wormhole = following_body #so its not confusing
		var wormholes = world.player.current_star_system.get_wormholes()
		var destination = following_wormhole.destination_system
		
		if destination and (not destination == world.player.previous_star_system):
			
			var new_query = responseQuery.new()
			new_query.add("concept", "followingBody")
			new_query.add("id", "wormhole")
			new_query.add_tree_access("name", following_wormhole.display_name)
			new_query.add_tree_access("pending_audio_profiles", world.get_pending_audio_profiles().size() > 0) #for AV FLAIR
			get_tree().call_group("dialogueManager", "speak", self, new_query)
			
			var RETURN_STATE = await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
			match RETURN_STATE:
				"ENTER_WORMHOLE":
					enter_wormhole(following_wormhole, wormholes, destination)
				_:
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_wormhole)
	
	elif following_body is stationAPI:
		var following_station = following_body
		
		var is_station_abandoned: bool = following_station.station_classification in [game_data.STATION_CLASSIFICATIONS.ABANDONED, game_data.STATION_CLASSIFICATIONS.ABANDONED_BACKROOMS, game_data.STATION_CLASSIFICATIONS.ABANDONED_OPERATIONAL, game_data.STATION_CLASSIFICATIONS.COVERUP, game_data.STATION_CLASSIFICATIONS.PARTIALLY_SALVAGED]
		var is_station_inhabited: bool = following_station.station_classification in [game_data.STATION_CLASSIFICATIONS.STANDARD, game_data.STATION_CLASSIFICATIONS.PIRATE]
		
		if following_station.metadata.get("is_available", true) == true:
			
			var new_query = responseQuery.new()
			new_query.add("concept", "followingBody")
			new_query.add("id", "station")
			new_query.add_tree_access("name", following_station.display_name)
			new_query.add_tree_access("station_classification", str(game_data.STATION_CLASSIFICATIONS.find_key(following_station.station_classification)))
			new_query.add_tree_access("is_station_abandoned", is_station_abandoned)
			new_query.add_tree_access("is_station_inhabited", is_station_inhabited)
			get_tree().call_group("dialogueManager", "speak", self, new_query)
			
			var RETURN_STATE = await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
			match RETURN_STATE:
				"DOCK_WITH_STATION":
					dock_with_station(following_station)
				"POST_SALVAGE_LEAVE": #this is for abandoned stations which yield salvage, which should not be repeatable
					following_station.metadata["is_available"] = false
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_station)
				_:
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_station)
	
	elif following_body.is_planet():
		var following_planet = following_body
		if following_planet.metadata.get("has_planetary_anomaly", false) == true:
			if following_planet.metadata.get("is_planetary_anomaly_available", false) == true:
				var new_query = responseQuery.new()
				new_query.add("concept", "followingBody")
				
				if init_type == global_data.GAME_INIT_TYPES.TUTORIAL:
					new_query.add("id", "planetaryAnomalyTutorialOverride")
				else:
					new_query.add("id", "planetaryAnomaly")
				
				new_query.add_tree_access("name", following_planet.display_name)
				new_query.add_tree_access("planet_classification", following_planet.metadata.get("planet_classification"))
				new_query.add_tree_access("custom_seed", following_planet.metadata.get("planetary_anomaly_seed"))
				get_tree().call_group("dialogueManager", "speak", self, new_query)
				
				var RETURN_STATE = await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
				match RETURN_STATE:
					"HARD_LEAVE":
						following_planet.metadata["is_planetary_anomaly_available"] = false
						_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_planet)
					"SOFT_LEAVE":
						following_planet.metadata["is_planetary_anomaly_available"] = true
						_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_planet)
					"HARD_LEAVE_STATION_OVERRIDE": #for planetary settlements
						following_planet.metadata["is_planetary_anomaly_available"] = false
						
						var temp_station: stationAPI = stationAPI.new()
						temp_station.set_display_name(game_data.get_random_name_from_variety(game_data.NAME_VARIETIES.STATION))
						temp_station.station_classification = game_data.STATION_CLASSIFICATIONS.PIRATE
						var random = RandomNumberGenerator.new()
						random.set_seed(following_planet.metadata.get("planetary_anomaly_seed", randi()))
						temp_station.sell_percentage_of_market_price = random.randi_range(25,75)
						dock_with_station(temp_station)
						
					_:
						_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_planet)
	
	elif following_body.is_anomaly():
		var following_anomaly = following_body
		if following_anomaly.metadata.get("is_space_anomaly_available", true) == true:
			
			var new_query = responseQuery.new()
			new_query.add("concept", "followingBody")
			new_query.add("id", "spaceAnomaly")
			new_query.add_tree_access("custom_seed", following_anomaly.metadata.get("space_anomaly_seed"))
			get_tree().call_group("dialogueManager", "speak", self, new_query)
			
			var RETURN_STATE = await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
			match RETURN_STATE:
				"HARD_LEAVE":
					following_anomaly.metadata["is_space_anomaly_available"] = false
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_anomaly)
				"SOFT_LEAVE":
					following_anomaly.metadata["is_space_anomaly_available"] = true
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_anomaly)
				"HARD_LEAVE_STATION_OVERRIDE": #for outposts
					following_anomaly.metadata["is_space_anomaly_available"] = false
					
					var temp_station: stationAPI = stationAPI.new()
					temp_station.set_display_name(game_data.get_random_name_from_variety(game_data.NAME_VARIETIES.STATION))
					temp_station.station_classification = game_data.STATION_CLASSIFICATIONS.PIRATE
					var random = RandomNumberGenerator.new()
					random.set_seed(following_anomaly.metadata.get("space_anomaly_seed", randi()))
					temp_station.sell_percentage_of_market_price = random.randi_range(25,75)
					dock_with_station(temp_station)
					
				_:
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_anomaly)
	
	elif following_body is entityAPI:
		var following_entity = following_body
		if world.player.discovered_entities.find(following_entity.entity_classification) == -1:
			world.player.discovered_entities.append(following_entity.entity_classification)
		long_range_scopes._on_current_entity_changed(following_entity)
		lrs_bestiary._on_current_entity_changed(following_entity)
		
		await system_map.validUpdatePlayerActionType
		long_range_scopes._on_current_entity_cleared()
	pass


func enter_wormhole(following_wormhole, wormholes, destination: starSystemAPI):
	#spawning new wormholes in destination system if nonexistent
	if not destination.destination_systems:
		for i in range(2):
			_on_create_new_star_system(false, destination)
		destination.generateRandomWormholes()
		destination.generateRandomWeightedEntities()
		destination.generateRandomAnomalies(world.SA_chance_per_candidate)
	
	#var destination_position: Vector2 = Vector2.ZERO
	var destination_wormhole: wormholeAPI = destination.get_wormhole_with_destination_system(world.player.current_star_system)
	#if destination_wormhole:
		#destination.updateBodyPosition(destination_wormhole.get_identifier(), 0.01) #REQURIED SO WORMHOLE HAVE A POSITION OTHER THAN 0,0
		#destination_position = destination_wormhole.position
		#_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, destination_wormhole)
		#system_3d.locked_body_identifier = destination_wormhole.get_identifier() #diesnt seem to work?!
		#print_debug(destination_wormhole)
		#print_debug(destination_wormhole.rotation)
		#world.player.position = destination.get_body_from_identifier(destination_wormhole.hook_identifier)
	destination_wormhole.is_known = true
	
	#setting whether the new system is a civilized system or not
	world.player.removeJumpsRemaining(1) #removing jumps remaining until reaching a civilized system
	if world.player.get_jumps_remaining() == 0:
		destination.generateRandomWeightedStations()
		world.player.resetJumpsRemaining()
		for body in destination.bodies:
			body.is_known = true
	
	#world.player.position = destination_position
	#world.player.target_position = world.player.position
	#system_map._on_start_movement_lock_timer()
	
	#no idea if anything below this point actually works so be careful \/\/\/\/
	
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
	
	_on_switch_star_system(destination)
	barycenter_visualizer.locked_body_identifier = destination_wormhole.get_identifier() #this is a bugfix (really?)
	
	wormhole_minigame.initialize(world.player.weirdness_index, world.player.hull_stress_wormhole)
	
	_on_wormhole_minigame_popup()
	pass

func dock_with_station(following_station):
	station_ui.station = following_station
	station_ui.player_current_value = world.player.current_value
	station_ui.player_balance = world.player.balance
	station_ui.player_hull_stress = world.player.hull_stress
	station_ui.set("player_saved_audio_profiles_size_matrix", [world.player.saved_audio_profiles.size(), world.player.max_saved_audio_profiles])
	station_ui.pending_audio_profiles = world.get_pending_audio_profiles()
	print_debug("PENDING AUDIO PROFILES: ", station_ui.pending_audio_profiles)
	
	_on_station_popup()
	pass



func _on_player_death():
	print("GAME (DEBUG): PLAYER DIED!!!!!!!!!!!")
	
	_on_open_stats_menu(stats_menu.INIT_TYPES.DEATH, world.player.systems_traversed)
	await stats_menu.onCloseStatsMenu
	
	global_data.change_scene.emit("res://Scenes/Main Menu/main_menu.tscn")
	game_data.deleteWorld()
	pass

func _on_player_win():
	print("GAME (DEBUG): PLAYER WON!!!!!!!!!!!!!!")
	
	var new_query = responseQuery.new()
	new_query.add("concept", "playerWin")
	get_tree().call_group("dialogueManager", "speak", self, new_query)
	
	await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
	
	_on_open_stats_menu(stats_menu.INIT_TYPES.WIN, world.player.systems_traversed)
	await stats_menu.onCloseStatsMenu
	
	global_data.change_scene.emit("res://Scenes/Main Menu/main_menu.tscn")
	game_data.deleteWorld()
	pass

func _on_update_player_action_type(type: playerAPI.ACTION_TYPES, action_body):
	if not (type == world.player.current_action_type and action_body == world.player.action_body):
		system_map.emit_signal("validUpdatePlayerActionType", type, action_body) #used for checking if the player is no longer orbiting a body in game.gd!
	
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

func _on_create_new_star_system(force_switch_before_post_gen: bool = false, for_system: starSystemAPI = null):
	var system = world.createStarSystem("random")
	var hook_star = system.createRandomWeightedPrimaryHookStar()
	system.generateRandomWeightedBodies(hook_star, world.PA_chance_per_planet, world.missing_AO_chance_per_planet)
	if for_system:
		for_system.destination_systems.append(system)
		system.previous_system = for_system
	if force_switch_before_post_gen:
		world.player.current_star_system = system
		system_map.system = system
		system_3d.system = system
		system_3d.spawnBodies()
	print("SYSTEM MAP (DEBUG): CREATING NEW STAR SYSTEM")
	return system

func _on_switch_star_system(to_system: starSystemAPI):
	if world.player.current_star_system:
		if world.player.current_star_system.bodies.find(audio_visualizer.current_audio_profile) != -1:
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
	return to_system

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
			body.is_known = true
			if body.metadata.has("value"): world.player.current_value += (body.metadata.get("value") * system.get_first_star_discovery_multiplier())
			system_map._on_found_body(id)
			var sub_bodies = system.get_bodies_with_hook_identifier(id)
			if sub_bodies:
				for sub_body in sub_bodies:
					if sub_body.is_asteroid_belt():
						sub_body.is_known = true
	pass

func _on_add_console_item(text: String, bg_color: Color = Color.WHITE, time: int = 500): #called via systtem 3d
	print_debug("ADD CONSOLE ITEM CALLED ", text, " ", bg_color, " ", time)
	system_map._on_add_console_item(text, bg_color, time)
	pass

func _on_sonar_ping(ping_width: int, ping_length: int, ping_direction: Vector2):
	print("SONAR INTERFACE (DEBUG): PINGING")
	system_map._on_sonar_ping(ping_width, ping_length, ping_direction)
	
	if ping_width > 35:
		var incurred_hull_stress = round(remap(ping_width, 10, 90, 0, world.player.hull_stress_highest_arc))
		_on_add_player_hull_stress(incurred_hull_stress)
		#can have multiple results here depending on what upgrades the player has related to the LIDAR
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
	pass

func _on_remove_saved_audio_profile(helper: audioProfileHelper):
	world.player.removeAudioProfile(helper)
	pass

func _on_add_saved_audio_profile(helper: audioProfileHelper):
	world.player.addAudioProfile(helper)
	station_ui.set("player_saved_audio_profiles_size_matrix", [world.player.saved_audio_profiles.size(), world.player.max_saved_audio_profiles])
	pass

func _on_add_player_value(amount: int) -> void:
	world.player.current_value += amount
	pass

func _on_add_player_hull_stress(amount: int) -> void:
	world.player.addHullStress(amount)
	pass

func _on_remove_player_hull_stress(amount: int) -> void:
	world.player.removeHullStress(amount)
	pass

func _on_player_hull_deterioration_changed(new_value: int) -> void:
	print_debug("_ON_PLAYER_HULL_DETERIORATION_CHANGED")
	if new_value == 100:
		_on_player_death()
	pass

func _on_kill_character_with_occupation(occupation: characterAPI.OCCUPATIONS) -> void:
	match occupation:
		characterAPI.OCCUPATIONS.FIRST_OFFICER:
			world.player.first_officer.is_alive = false
		characterAPI.OCCUPATIONS.CHIEF_ENGINEER:
			world.player.chief_engineer.is_alive = false
		characterAPI.OCCUPATIONS.SECURITY_OFFICER:
			world.player.security_officer.is_alive = false
		characterAPI.OCCUPATIONS.MEDICAL_OFFICER:
			world.player.medical_officer.is_alive = false
		characterAPI.OCCUPATIONS.LINGUIST:
			world.player.linguist.is_alive = false
		characterAPI.OCCUPATIONS.HISTORIAN:
			world.player.historian.is_alive = false
		_:
			pass
	pass

func _on_update_player_is_boosting(is_boosting: bool):
	world.player.is_boosting = is_boosting
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

func _on_open_stats_menu(_init_type: int, player_systems_traversed: int): #init type is from statsMenu INIT_TYPES
	stats_menu.init_type = _init_type
	stats_menu._player_systems_traversed = player_systems_traversed
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
	_on_open_stats_menu(stats_menu.INIT_TYPES.WIN, world.player.systems_traversed)
	await stats_menu.onCloseStatsMenu
	global_data.change_scene.emit("res://Scenes/Main Menu/main_menu.tscn")
	pass

func _on_add_player_morale(amount : int) -> void:
	world.player.addMorale(amount)
	pass

func _on_remove_player_morale(amount : int) -> void:
	world.player.removeMorale(amount)
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
	pass


func _ON_DEBUG_REVEAL_ALL_WORMHOLES():
	for body in world.player.current_star_system.bodies:
		if body.is_wormhole():
			body.is_known = true
	pass

func _ON_DEBUG_REVEAL_ALL_BODIES():
	for body in world.player.current_star_system.bodies:
		body.is_known = true
	pass









func _on_audio_visualizer_popup():
	audio_visualizer._on_popup()
	if $audio_visualizer_window.is_visible():
		$audio_visualizer_window.hide()
	else:
		$audio_visualizer_window.move_to_center()
		$audio_visualizer_window.popup()
		_on_add_console_item("Opening audio visualizer.", Color("353535"), 50)
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
		_on_add_console_item("Opening journey map.", Color("353535"), 50)
	pass

func _on_long_range_scopes_popup():
	if $long_range_scopes_window.is_visible():
		$long_range_scopes_window.hide()
	else:
		$long_range_scopes_window.move_to_center()
		$long_range_scopes_window.popup()
		_on_add_console_item("Opening long range scopes.", Color("353535"), 50)
	pass
