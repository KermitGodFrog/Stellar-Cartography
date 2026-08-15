extends Node
#Handles most game stuff that is not local to child windows, loads data, saves data, the whole thing. child windows must route data through this to change the world/system/player

var init_type: int = 0 #from global data GAME_INIT_TYPES
var init_data: Dictionary = {}
var world: worldAPI
var allow_quick_pause: bool = false

@onready var system_map = $system_window/system
@onready var system_3d = $system_window/system/camera/canvas/control/scopes_snap_scroll/scopes_bg/scopes_margin/scopes_container/system_3d_window/system_3d
@onready var sonar = $system_window/system/camera/canvas/control/scopes_snap_scroll/core_and_value_scroll/core/core_scroll/core_panel/core_margin/core_scroll/sonar_container/sonar_window/sonar_control
@onready var barycenter_visualizer = $system_window/system/camera/canvas/control/scopes_snap_scroll/core_and_value_scroll/core/core_scroll/core_panel/core_margin/core_scroll/barycenter_container/barycenter_visualizer_window/barycenter_control
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
@onready var debug_interface = $debug_interface_window/debug_interface

func _ready():
	connect_all_signals()
	
	world = game_data.loadWorld()
	if init_type == global_data.GAME_INIT_TYPES.TUTORIAL:
		world = game_data.createWorld(25, 5, 25, 15, 5, 10, 25.0, 50.0, 0.005, 0.05, 0.25, 0.10)
		
		dialogue_manager.dialogue_memory = world.dialogue_memory
		
		var new_player = world.createPlayer(
			init_data.get("name", "Tanaka"),
			init_data.get("ship_name", "Valiant"),
			init_data.get("prefix", "Captain"))
		new_player.resetJumpsRemaining()
		
		_on_unlock_upgrade(playerAPI.UPGRADE_ID.SCAN_PREDICTION)
		_on_unlock_upgrade(playerAPI.UPGRADE_ID.BACKGROUND_PROCESSING)
		
		connect_all_player_signals(new_player)
		
		var king: starSystemAPI = load("uid://bpnb60fo3ghca").duplicate(true)
		var suno: starSystemAPI = load("uid://bhqtlq0blu17n").duplicate(true)
		world.star_systems.append(king)
		world.star_systems.append(suno)
		
		world.player.systems_traversed = -6
		journey_map.generate_up_to_system(world.player.systems_traversed)
		
		_on_switch_star_system(king)
		
		_on_update_player_action_type(playerAPI.ACTION_TYPES.NONE, null)
		world.player.position = Vector2(60, 0)
		world.player.setTargetPosition(world.player.position)
		world.player.updatePosition(get_physics_process_delta_time())
		
		pause_menu.disableSaving() # so savefile cannto be overwriten
		
		#system_3d.update_FOV_constraints(world.player.scopes_min_FOV, world.player.scopes_max_FOV)
		#sonar.update_cooldown(world.player.LIDAR_cooldown)
		
		objectives_manager.start_receive_init_type(init_type)
		
		await get_tree().create_timer(1.0, true).timeout
		
		system_map.setup_tutorial_processor()
		system_map.setup_tutorial_info_popups()
		
		var new_query = responseQuery.new()
		new_query.add("concept", "tutorialPlayerStart")
		get_tree().call_group("dialogueManager", "speak", self, new_query)
		
		allow_quick_pause = true
	
	elif world == null or init_type == global_data.GAME_INIT_TYPES.NEW:
		world = game_data.createWorld(25, 5, 25, 15, 5, 10, 25.0, 50.0, 0.005, 0.05, 0.25, 0.10)
		
		dialogue_manager.dialogue_memory = world.dialogue_memory
		
		var new_player = world.createPlayer(
			init_data.get("name", "Tanaka"), 
			init_data.get("ship_name", "Valiant"),
			init_data.get("prefix", "Captain"))
		new_player.resetJumpsRemaining()
		
		_on_unlock_upgrade(playerAPI.UPGRADE_ID.SCAN_PREDICTION)
		_on_unlock_upgrade(playerAPI.UPGRADE_ID.BACKGROUND_PROCESSING)
		
		connect_all_player_signals(new_player)
		
		#new game stuff
		var ghost: starSystemAPI = _on_create_new_star_system()
		var new: starSystemAPI = _on_create_new_star_system(ghost)
		for i in range(2):
			_on_create_new_star_system(new)
		new.createAuxiliaryCivilized()
		
		_on_switch_star_system(new)
		
		_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, new.get_first_star())
		
		#system_3d.update_FOV_constraints(world.player.scopes_min_FOV, world.player.scopes_max_FOV)
		#sonar.update_cooldown(world.player.LIDAR_cooldown)
		
		objectives_manager.start_receive_init_type(init_type)
		
		await get_tree().create_timer(1.0, true).timeout
		
		var new_query = responseQuery.new()
		new_query.add("concept", "playerStart")
		get_tree().call_group("dialogueManager", "speak", self, new_query)
		
		await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
		
		game_data.saveWorld(world) #so if the player leaves before saving, the save file does not go back to a previous game!
		
		get_tree().call_group("audioHandler", "queue_music", "res://sound/music/intro.wav")
		
		allow_quick_pause = true
	
	elif init_type == global_data.GAME_INIT_TYPES.CONTINUE:
		
		dialogue_manager.dialogue_memory = world.dialogue_memory
		
		connect_all_player_signals(world.player)
		
		for i in world.player.current_star_system.destination_systems:
			i.previous_system = world.player.current_star_system #really important  actually
		
		for upgrade in world.player.unlocked_upgrades:
			_on_upgrade_state_change(upgrade, true)
		
		#system_3d.update_FOV_constraints(world.player.scopes_min_FOV, world.player.scopes_max_FOV)
		#sonar.update_cooldown(world.player.LIDAR_cooldown)
		
		journey_map.generate_up_to_system(world.player.systems_traversed)
		
		objectives_manager.start_receive_active_objectives(world.active_objectives)
		objectives_manager.start_receive_init_type(init_type)
		
		_on_switch_star_system(world.player.current_star_system)
		
		for body in world.player.current_star_system.bodies:
			if body is AIUnitAPI:
				body.set_system(world.player.current_star_system)
				body.set_player(world.player)
		
		await get_tree().create_timer(1.0, true).timeout
		allow_quick_pause = true
	
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
	system_map.connect("updatePlayerInPulsarBeam", _on_update_player_in_pulsar_beam)
	system_map.connect("updatePlayerInNebula", _on_update_player_in_nebula)
	system_map.connect("playerInPulsarBeamCooldownExpired", _on_player_in_pulsar_beam_cooldown_expired)
	system_map.connect("toggleScopeModeSwitchButton", _on_toggle_scope_mode_switch_button)
	system_map.connect("openPauseMenu", _on_open_pause_menu)
	system_map.connect("tutorialIngressThresholdReached", _on_tutorial_ingress_threshold_reached)
	system_map.connect("documentPingHitStatus", _on_document_ping_hit_status)
	system_map.connect("proximityBlinkerConditionChanged", _on_proximity_blinker_condition_changed)
	
	system_3d.connect("foundBody", _on_found_body)
	system_3d.connect("addConsoleEntry", _on_add_console_entry)
	
	sonar.connect("sonarPing", _on_sonar_ping)
	sonar.connect("sonarValuesChanged", _on_sonar_values_changed)
	
	station_ui.connect("sellExplorationData", _on_sell_exploration_data)
	station_ui.connect("upgradeShip", _on_upgrade_ship)
	station_ui.connect("refundUpgrade", _on_refund_upgrade)
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
	dialogue_manager.connect("removePlayerValue", _on_remove_player_value)
	dialogue_manager.connect("addPlayerHullStress", _on_add_player_hull_stress)
	dialogue_manager.connect("removePlayerHullStress", _on_remove_player_hull_stress)
	dialogue_manager.connect("addPlayerMorale", _on_add_player_morale)
	dialogue_manager.connect("removePlayerMorale", _on_remove_player_morale)
	dialogue_manager.connect("killCharacterWithOccupation", _on_kill_character_with_occupation)
	dialogue_manager.connect("foundBody", _on_found_body)
	dialogue_manager.connect("upgradeShip", _on_upgrade_ship)
	dialogue_manager.connect("rollNavBuoy", _on_roll_nav_buoy)
	dialogue_manager.connect("superchargePlayerForJumps", _on_supercharge_player_for_jumps)
	dialogue_manager.connect("modifyCharacterStanding", _on_modify_character_standing)
	dialogue_manager.connect("changePlayerScopeMode", _on_change_scope_mode)
	dialogue_manager.connect("lockUpgrade", _on_lock_upgrade)
	dialogue_manager.connect("addCharacterXP", _on_add_character_xp)
	dialogue_manager.connect("removeCharacterInitiativeXP", _on_remove_character_initiative_xp)
	dialogue_manager.connect("playerWin", _on_player_win)
	dialogue_manager.connect("playStrangeDiscoveryThemeOrMotif", _on_play_strange_discovery_theme_or_motif)
	dialogue_manager.connect("insaMakeAllWormholesRevealable", _on_insa_make_all_wormholes_revealable)
	dialogue_manager.connect("insaMakeRiftDriverUnavailable", _on_insa_make_rift_driver_unavailable)
	dialogue_manager.connect("insaMakeMilitaryShipsNeutral", _on_insa_make_military_ships_neutral)
	dialogue_manager.connect("TUTORIALSetIngressOverride", _on_tutorial_set_ingress_override)
	dialogue_manager.connect("TUTORIALSetOmissionOverride", _on_tutorial_set_omission_override)
	dialogue_manager.connect("TUTORIALPlayerWin", _on_tutorial_player_win)
	dialogue_manager.connect("TUTORIALEnterIngress", _on_tutorial_enter_ingress)
	dialogue_manager.connect("TUTORIALSetWindowTutorials", _on_tutorial_set_window_tutorials)
	dialogue_manager.connect("TUTORIALSetPlayerActionLock", _on_tutorial_set_player_action_lock)
	dialogue_manager.connect("TUTORIALForceOrbitPrelude", _on_tutorial_force_orbit_prelude)
	dialogue_manager.connect("TUTORIALSetUIStage", _on_tutorial_set_ui_stage)
	
	pause_menu.connect("saveWorld", _on_save_world)
	pause_menu.connect("saveAndQuit", _on_save_and_quit)
	pause_menu.connect("exitToMainMenu", _on_exit_to_main_menu)
	
	stats_menu.connect("statsMenuQuit", _on_stats_menu_quit)
	
	wormhole_minigame.connect("addPlayerHullStress", _on_add_player_hull_stress)
	
	objectives_manager.connect("activeObjectivesChanged", _on_active_objectives_changed)
	objectives_manager.connect("updateObjectivesPanel", _on_update_objectives_panel)
	objectives_manager.connect("addConsoleEntry", _on_add_console_entry)
	
	gas_layer_surveyor.connect("addPlayerValue", _on_add_player_value)
	
	debug_interface.connect("increasePlayerBalance", _on_increase_player_balance)
	debug_interface.connect("addPlayerDataValue", _on_add_player_value)
	debug_interface.connect("addPlayerHullStress", _on_add_player_hull_stress)
	debug_interface.connect("clearLoadRules", _on_DEBUG_clear_load_rules)
	debug_interface.connect("revealAllWormholes", _on_DEBUG_reveal_all_wormholes)
	debug_interface.connect("revealAllBodies", _on_DEBUG_reveal_all_bodies)
	debug_interface.connect("forceQuitDialogue", _on_DEBUG_force_quit_dialogue)
	debug_interface.connect("forceUnexploredSystem", _on_DEBUG_force_unexplored_system)
	debug_interface.connect("maxCharacterStanding", _on_DEBUG_max_character_standing)
	debug_interface.connect("removePlayerMorale", _on_remove_player_morale)
	debug_interface.connect("quickTraverse", _on_DEBUG_quick_traverse)
	debug_interface.connect("unlockUpgrade", _on_unlock_upgrade)
	debug_interface.connect("regenerateSystem3D", _on_DEBUG_regenerate_system_3d)
	debug_interface.connect("addCharacterXP", _on_add_character_xp)
	
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

func connect_all_player_signals(_player: playerAPI) -> void:
	_player.connect("orbitingBody", _on_player_orbiting_body)
	_player.connect("followingBody", _on_player_following_body)
	_player.connect("hullDeteriorationChanged", _on_player_hull_deterioration_changed)
	_player.connect("moraleChanged", _on_player_morale_changed)
	_player.connect("dataValueChanged", _on_player_data_value_changed)
	_player.connect("actionTypePendingOrCompleted", _on_player_action_type_pending_or_completed)
	_player.connect("scannerContactGained", _on_player_scanner_contact_gained)
	_player.connect("scannerContactLost", _on_player_scanner_contact_lost)
	pass

func _physics_process(delta):
	#EVERYTHING HERE MUST ONLY FUNCTION WHEN THE GAME IS UNPAUSED!
	
	#CORE GAME LOGIC \/\/\/\/\/
	#updating positions of everyhthing for API's
	world.player.updateActionBodyState()
	world.player.updatePosition(delta)
	world.player.updateScannerContacts(world.player.current_star_system.get_units_in_scanner_range(
		world.player.position, 
		world.player.get_adjusted_scanner_power()
	))
	world.player.tick_invulnerability_time(delta)
	world.player.current_star_system.updateBodies(delta)
	for i in world.player.current_star_system.updateMinesGetDetonations(world.player.position, delta, world.player.is_invulnerable()):
		_on_add_player_hull_stress(world.player.hull_stress_mine)
	
	system_map.update_alarm_sound(world.is_player_in_interception_danger())
	system_map.update_proximity_blinker(world.is_player_in_proximity_danger())
	
	#updating positions of everyhthing for windows
	pause_mode_handler.set("world", world)
	system_map.set("player_position_matrix", [world.player.position, world.player.target_position])
	system_map.set("_player_status_matrix", [world.player.balance, world.player.hull_stress, world.player.hull_deterioration, world.player.morale])
	system_map.set("player_adj_scanner_matrix", [world.player.get_adjusted_scanner_profile(), world.player.get_adjusted_scanner_power()])
	system_map.set("player_adj_speed", world.player.get_adjusted_speed())
	system_map.set("player_audio_visualizer_unlocked", (world.player.unlocked_upgrades.find(world.player.UPGRADE_ID.AUDIO_VISUALIZER) != -1))
	system_map.set("player_gas_layer_surveyor_unlocked", (world.player.unlocked_upgrades.find(world.player.UPGRADE_ID.GAS_LAYER_SURVEYOR) != -1))
	system_map.set("player_long_range_scopes_unlocked", (world.player.unlocked_upgrades.find(world.player.UPGRADE_ID.LONG_RANGE_SCOPES) != -1))
	system_map.set("player_action_lock", world.player.action_lock)
	system_3d.set("player_position", world.player.position)
	system_3d.set("min_FOV", world.player.scopes_min_FOV)
	system_3d.set("max_FOV", world.player.scopes_max_FOV)
	long_range_scopes.set("player_position", world.player.position)
	barycenter_visualizer.set("_player_position", world.player.position)
	audio_visualizer.set("saved_audio_profiles_size_matrix", [world.player.saved_audio_profiles.size(), world.player.max_saved_audio_profiles])
	audio_visualizer.set("saved_audio_profiles", world.player.saved_audio_profiles)
	dialogue_manager.set("player", world.player)
	gas_layer_surveyor.set("_discovered_gas_layers_matrix", world.player.discovered_gas_layers)
	sonar.set("cooldown", world.player.LIDAR_cooldown)
	
	audio_handler.enable_music_criteria["audio_visualizer_not_visible"] = !$audio_visualizer_window.is_visible()
	audio_handler.enable_music_criteria["countdown_processor_not_active"] = !countdown_processor != null
	
	game_data.player_weirdness_index = world.player.weirdness_index #really hacky solution which should not have been done this way but im too tired to change the entire game now to accomodate it.
	
	if Input.is_action_just_pressed("SC_PAUSE"):
		_on_open_pause_menu(true) #since game.gd is unpaused only, the pause menu can only open when the game is unpaused
		get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED | SceneTree.GROUP_CALL_UNIQUE, "eventsHandler", "speak", self, "pause_menu_show")
	elif Input.is_action_just_pressed("SC_QUICK_PAUSE") and allow_quick_pause:
		_on_open_pause_menu(false)
	
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
	new_query.add_tree_access("known", orbiting_body.is_known())
	
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
	if following_body.is_known():
		new_query.add("concept", "followingBody")
	else:
		new_query.add("concept", "followingUnknownBody")
		new_query.add_tree_access("required_scope_mode", following_body.get_required_scope_mode())
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
			if following_body.destination_system != null:
				new_query.add_tree_access("dest_special_system_classification", str(game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.find_key(following_body.destination_system.special_system_classification)))
				new_query.add_tree_access("dest_system_hazard_classification", str(game_data.SYSTEM_HAZARD_CLASSIFICATIONS.find_key(following_body.destination_system.system_hazard_classification)))
				new_query.add_tree_access("dest_system_scenario_classification", str(game_data.SYSTEM_SCENARIO_CLASSIFICATIONS.find_key(following_body.destination_system.system_scenario_classification)))
			else:
				new_query.add_tree_access("dest_special_system_classification", null)
				new_query.add_tree_access("dest_system_hazard_classification", null)
				new_query.add_tree_access("dest_system_scenario_classification", null)
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
		starSystemAPI.BODY_TYPES.SHIP:
			body_query_add_unit_type_shared(new_query, following_body)
			new_query.add("ship_available", following_body.metadata.get("ship_available", true))
			new_query.add_tree_access("seed", following_body.metadata.get("seed", 0))
			var unlocked_upgrades = world.player.get_unlocked_upgrades()
			if unlocked_upgrades.size() > 0:
				new_query.add_tree_access("target_upgrade", playerAPI.UPGRADE_ID.find_key(unlocked_upgrades[global_data.get_randi(0, unlocked_upgrades.size() - 1, following_body.metadata.get("seed", 0))]))
			else:
				new_query.add_tree_access("target_upgrade", null)
	
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
					var temp_station := starSystemAPI.get_temporary_station(following_body)
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
					var temp_station := starSystemAPI.get_temporary_station(following_body)
					dock_with_station(temp_station)
				_:
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_body)
		starSystemAPI.BODY_TYPES.SHIP:
			match RETURN_STATE:
				"HARD_LEAVE":
					following_body.metadata["ship_available"] = false
					_on_update_player_action_type(playerAPI.ACTION_TYPES.NONE, null)
				"SOFT_LEAVE":
					following_body.metadata["ship_available"] = true
					_on_update_player_action_type(playerAPI.ACTION_TYPES.NONE, null)
				"HARD_LEAVE_MAKE_PEACEFUL_OVERRIDE":
					following_body.metadata["ship_available"] = false
					following_body.metadata["hostile"] = false
					_on_update_player_action_type(playerAPI.ACTION_TYPES.NONE, null)
				_:
					_on_update_player_action_type(playerAPI.ACTION_TYPES.NONE, null)
		_:
			_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_body)
	pass

func body_query_add_shared(query: responseQuery, body: bodyAPI) -> void:
	query.add("type", starSystemAPI.BODY_TYPES.find_key(body.get_type()))
	query.add_tree_access("name", body.get_display_name())
	query.add("tutorial", init_type == global_data.GAME_INIT_TYPES.TUTORIAL)
	query.add("tutorial_type", init_data.get("tutorial_type", null))
	query.add("insa", world.player.current_star_system.special_system_classification == game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.INSA)
	pass

func body_query_add_custom_type_shared(query: responseQuery, body: bodyAPI) -> void: #shared between theorisedBody, orbitingBody, followingBody
	query.add("custom_tag", body.get_dialogue_tag())
	query.add("custom_available", body.metadata.get("custom_available", true))
	query.add_tree_access("seed", body.metadata.get("seed", 0))
	pass

func body_query_add_unit_type_shared(query: responseQuery, body: bodyAPI) -> void:
	query.add_tree_access("unit_affiliation", str(game_data.UNIT_AFFILIATIONS.find_key(body.metadata.get("affiliation"))))
	query.add_tree_access("unit_hostile", body.metadata.get("hostile", false))
	pass


func _on_unit_following_body(_b: bodyAPI, _u: unitBodyAPI) -> void:
	await get_tree().physics_frame #might fix issues where unit interacts before dialogue_manager receives player on first physics frame causing error
	if _b == world.player:
		_on_player_following_body(_u)
	elif _b is theatreMilitaryUnitAPI:
		_b.stun(2.5, true)
	pass

func _on_unit_orbiting_body(_b: bodyAPI, _u: unitBodyAPI) -> void:
	await get_tree().physics_frame #might fix issues where unit interacts before dialogue_manager receives player on first physics frame causing error
	pass


func _on_player_death():
	if pause_mode_handler.pause_mode != game_data.PAUSE_MODES.NONE: #unnecessary since a mutiny SHOULDNT ever happen outside of when dialogue is already open
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
	new_query.add_tree_access("system_scenario_classification", str(game_data.SYSTEM_SCENARIO_CLASSIFICATIONS.find_key(system.system_scenario_classification)))
	new_query.add_tree_access("system_star_type", system.get_first_star().metadata.get("star_type"))
	new_query.add_tree_access("system_civilized", system.is_civilized())
	new_query.add_tree_access("seed", system.non_gen_seed)
	get_tree().call_group("dialogueManager", "speak", self, new_query)
	
	#not awaiting onCloseDialog because wacky shtuff happens!!!!!!! audioHandler should only play it when pause_mode is NONE anyway
	
	if system.special_system_classification == game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.INSA:
		get_tree().call_group("audioHandler", "queue_music", "res://sound/music/insa.ogg")
	elif system.is_civilized():
		_on_play_civilized_system_leitmotif()
	elif system.get_first_star().metadata.get("star_type") == "Pulsar":
		if not world.played_pulsar_theme:
			get_tree().call_group("audioHandler", "queue_music", "res://sound/music/pulsar.ogg")
			world.played_pulsar_theme = true
	pass

func _on_player_mutiny() -> void:
	if pause_mode_handler.pause_mode != game_data.PAUSE_MODES.NONE: #unnecessary since a mutiny SHOULDNT ever happen outside of when dialogue is already open
		await pause_mode_handler.pauseModeNone
	print("GAME: PLAYER MUTINY")
	
	var new_query = responseQuery.new()
	new_query.add("concept", "playerMutiny")
	get_tree().call_group("dialogueManager", "speak", self, new_query)
	
	var RETURN_STATE = await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
	match RETURN_STATE:
		"LOSE_MUTINY":
			print("GAME: PLAYER LOSE_MUTINY")
			world.player.survived_mutiny = false
			_on_player_death()
		"WIN_MUTINY":
			print("GAME: PLAYER WIN_MUTINY")
			world.player.survived_mutiny = true
		_:
			pass
	pass

func _on_async_upgrade_tutorial(upgrade_idx: playerAPI.UPGRADE_ID):
	match upgrade_idx:
		playerAPI.UPGRADE_ID.LONG_RANGE_SCOPES:
			var new_query = responseQuery.new()
			new_query.add("concept", "moduleTutorial")
			new_query.add("module", "longRangeScopes")
			get_tree().call_group("dialogueManager", "speak", self, new_query)
		
		playerAPI.UPGRADE_ID.AUDIO_VISUALIZER:
			var new_query = responseQuery.new()
			new_query.add("concept", "moduleTutorial")
			new_query.add("module", "audioVisualizer")
			get_tree().call_group("dialogueManager", "speak", self, new_query)
			
		playerAPI.UPGRADE_ID.NANITE_CONTROLLER:
			var new_query = responseQuery.new()
			new_query.add("concept", "moduleTutorial")
			new_query.add("module", "naniteController")
			get_tree().call_group("dialogueManager", "speak", self, new_query)
			
		playerAPI.UPGRADE_ID.GAS_LAYER_SURVEYOR:
			var new_query = responseQuery.new()
			new_query.add("concept", "moduleTutorial")
			new_query.add("module", "gasLayerSurveyor")
			get_tree().call_group("dialogueManager", "speak", self, new_query)
		
	pass


func enter_wormhole(following_wormhole, wormholes, destination: starSystemAPI, skip_minigame: bool = false):
	world.player.grant_invulnerability(0.3)
	world.player.systems_traversed += 1
	
	#spawning new wormholes in destination system if nonexistent
	if not destination.destination_systems:
		var next_weirdness_index: float = remap(world.player.systems_traversed + 1, 0, world.player.total_systems, 0.0, 1.0)
		_on_create_new_star_system(destination, next_weirdness_index, false)
		_on_create_new_star_system(destination, next_weirdness_index, (world.player.systems_traversed + 1) == world.player.total_systems)
	#setting whether the new system is a civilized system or not
	world.player.removeJumpsRemaining(1) #removing jumps remaining until reaching a civilized system
	if world.player.get_jumps_remaining() == 0:
		world.player.resetJumpsRemaining()
		destination.createAuxiliaryCivilized(world.player.get_unlocked_upgrades())
	else:
		destination.createAuxiliaryUnexplored(world.player.speed)
	
	
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
	
	if world.player.systems_traversed == world.player.total_systems + 1: # will need a global variable for how many ssystems until win at some point, customizability would be sick
		_on_player_win()
	
	#setting position to wormhole??? actually works??????
	_on_update_player_action_type(playerAPI.ACTION_TYPES.NONE, null)
	for body in destination.bodies:
		destination.updateBodyPosition(body.get_identifier(), get_physics_process_delta_time())
		#SETTING PLAYER FOR AI UNITS IN DESTINATION
		if body is AIUnitAPI:
			body.set_player(world.player)
	world.player.position = destination_wormhole.position
	world.player.setTargetPosition(world.player.position)
	world.player.updatePosition(get_physics_process_delta_time())
	
	system_map._on_clear_console_entries()
	var time_dict = Time.get_time_dict_from_system()
	print_debug("[%02d:%02d:%02d] LAST SYSTEM SURVEY VALUE: %d" % [time_dict.hour, time_dict.minute, time_dict.second, world.player.sys_survey_value])
	_on_switch_star_system(destination)
	barycenter_visualizer.locked_body_identifier = 0
	
	#removed from the late _on_movement_lock_timer_start function - probably does nothing but im too scared to not add it here just in case
	system_map.follow_body = null
	system_map.locked_body = null
	system_map.action_body = null
	
	wormhole_minigame.initialize(world.player.weirdness_index, world.player.hull_stress_wormhole)
	if not skip_minigame:
		_on_wormhole_minigame_popup()
	
	world.player.reset_all_sys_survey_data() #for sys survey efficiency bonus
	world.player.sys_survey_time_start = world.play_time
	
	_on_player_entering_system(destination) #this dialogue is overwritten if the player dies during traversal!
	pass

func dock_with_station(following_station):
	station_ui.station = following_station
	station_ui.player_current_value = world.player.current_value
	station_ui.player_balance = world.player.balance
	station_ui.player_hull_stress = world.player.hull_stress
	station_ui.player_SPL_upgrades_matrix = [world.player.current_SPL_upgrades, world.player.max_SPL_upgrades]
	station_ui.player_unlocked_upgrades = world.player.get_unlocked_upgrades()
	
	station_ui.set("player_saved_audio_profiles_size_matrix", [world.player.saved_audio_profiles.size(), world.player.max_saved_audio_profiles])
	station_ui.set("pending_audio_profiles", world.get_pending_audio_profiles())
	_on_station_popup()
	pass

#misc signal handling

func _on_update_player_action_type(type: playerAPI.ACTION_TYPES, action_body):
	if not (type == world.player.current_action_type and action_body == world.player.action_body):
		long_range_scopes._on_current_entity_cleared()
		gas_layer_surveyor._on_current_planet_cleared()
	
	world.player.set_action_type(type, action_body)
	pass

func _on_update_player_target_position(pos: Vector2):
	world.player.target_position = pos
	pass

func _on_update_target_position(pos: Vector2):
	system_3d.set("target_position", pos)
	pass

func _on_create_new_star_system(for_system: starSystemAPI = null, for_weirdness_index: float = 0.0, insa_override: bool = false):
	game_data.SYSTEM_PREFIX = "" #shuldnt be calling game_data from game.gd but whateverrrrrrr
	var system: starSystemAPI
	if not insa_override:
		system = world.createStarSystem("random")
	else:
		system = world.createStarSystem("campaign_insa")
		system.special_system_classification = game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.INSA
	var _advanced_scanning_unlocked = world.player.is_upgrade_unlocked(playerAPI.UPGRADE_ID.ADVANCED_SCANNING)
	system.non_gen_seed = randi() #for ESDs
	system.createBase(world.get_adjusted_PA_chance(_advanced_scanning_unlocked), world.missing_AO_chance_per_planet, world.get_adjusted_SA_chance(_advanced_scanning_unlocked), world.missing_GL_chance_per_relevant_planet, for_weirdness_index)
	if for_system != null:
		for_system.destination_systems.append(system)
		system.previous_system = for_system
	print("GAME: CREATING NEW STAR SYSTEM ", system)
	return system

func _on_switch_star_system(to_system: starSystemAPI):
	print_debug("GAME: SWITCHING STAR SYSTEM ", to_system)
	
	#this ENSURES that units can follow the player AFTER reload or at any time since _on_switch_star_system is called on both CONTINUE and NEW. unitBodyAPIs must be made *BEFORE* _on_switch_star_system as a result.
	_on_reconnect_system_signals(to_system)
	
	#if world.player.current_star_system:
		#if world.player.current_star_system.bodies.find(audio_visualizer.current_audio_profile) != -1: #this was the thing throwing TypedArray does not inherit from GDScript errors, so I just removed it.... hopefully ok. does not look important at all
	audio_visualizer._on_clear_button_pressed()
	
	world.player.current_star_system = to_system
	system_map.system = to_system
	system_3d.system = to_system
	barycenter_visualizer.system = to_system
	long_range_scopes.system = to_system
	dialogue_manager.system = to_system
	
	system_3d.regenerate_system()
	system_3d.reset_locked_body()
	system_map._on_new_background()
	journey_map.add_new_system(world.player.systems_traversed)
	journey_map.jumps_remaining = world.player.get_jumps_remaining() #required as it needs to update when the players system on game startup is loaded, not just wormhole traversal!
	system_map.player_supercharged = world.player.supercharged #also updated when player supercharge_jumps_remaining is updated
	system_map.custom_textures_cache.clear()
	_on_process_system_hazard(to_system)
	return to_system

func _on_reconnect_system_signals(system: starSystemAPI) -> void:
	for unit: unitBodyAPI in system.get_units():
		unit.try_reconnect_signal_callable_pairs()
		var unit_connections: Dictionary = {
			unit.followingBody: system._on_unit_following_body, 
			unit.orbitingBody: system._on_unit_orbiting_body,
			unit.play_sound: system._on_unit_play_sound,
		}
		for s: Signal in unit_connections:
			if not s.is_connected(unit_connections[s]):
				s.connect(unit_connections[s].bind(unit))
	
	var system_connections: Dictionary = {
		system.unit_following_body: _on_unit_following_body,
		system.unit_orbiting_body: _on_unit_orbiting_body,
		system.unit_play_sound: _on_unit_play_sound,
		system.mine_detonated: _on_mine_detonated,
		system.body_removed: _on_body_removed
	}
	for s: Signal in system_connections:
		if not s.is_connected(system_connections[s]):
			s.connect(system_connections[s])
	pass

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
			var processor = load("uid://cuc55f8drt4bt")
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
	var system: starSystemAPI = world.get_system_from_identifier(world.player.current_star_system.get_identifier()) #are we deadass. what is this.       <--- dumbest line of code i have ever seen (22/7/26)
	if system:
		var body = system.get_body_from_identifier(id)
		if body:
			body.known = true
			if body.metadata.has("value"): 
				var adjusted_value: int = (body.metadata.get("value") * system.get_first_star_discovery_multiplier())
				world.player.current_value += adjusted_value
				world.player.sys_survey_value += adjusted_value
			system_map._on_found_body(id)
			var sub_bodies = system.get_bodies_with_hook_identifier(id)
			if sub_bodies:
				for sub_body in sub_bodies:
					if sub_body.get_type() == starSystemAPI.BODY_TYPES.ASTEROID_BELT:
						sub_body.known = true
			
			if barycenter_visualizer.locked_body_identifier == id:
				barycenter_visualizer.set("locked_body_identifier", id)
			
			if system.is_survey_complete():
				
				if init_type == global_data.GAME_INIT_TYPES.TUTORIAL and body.get_display_name() == "Prelude": #ugly tutorial override UGHH
					return
				
				_on_sys_survey_efficiency_bonus()
	pass

func _on_add_console_entry(entry_text: String, text_color: Color = Color.WHITE): #called via systtem 3d
	system_map._on_add_console_entry(entry_text, text_color)
	pass

func _on_sonar_ping(ping_width: int, ping_length: int, ping_direction: Vector2):
	system_map._on_sonar_ping(ping_width, ping_length, ping_direction)
	pass

func _on_sonar_values_changed(ping_width: int, ping_length: int, ping_direction: Vector2):
	system_map._on_sonar_values_changed(ping_width, ping_length, ping_direction)
	barycenter_visualizer._ping_length = ping_length
	barycenter_visualizer._ping_direction = ping_direction
	pass

func _on_sell_exploration_data(sell_percentage_of_market_price: int):
	print("GAME: SELLING EXPLORATION DATA")
	var multiplier = sell_percentage_of_market_price / 100.0
	var sell_for = world.player.current_value * multiplier #star system multiplier is already added to value
	
	#dont worry, audio profiles are added by observed_bodies_list.gd when opened, and are added to player current value - i dont know what that means either, go find out yourself idk idk idk
	
	world.player.increaseBalance(sell_for)
	world.player.current_value = 0
	station_ui.player_balance = world.player.balance
	
	world.player.analytics_exploration_data_payouts.append(sell_for)
	pass

func _on_upgrade_ship(upgrade_idx: playerAPI.UPGRADE_ID, cost: int):
	print("GAME: UPGRADING SHIP")
	if world.player.balance >= cost and (world.player.is_upgrade_unlock_valid(upgrade_idx)):
		world.player.decreaseBalance(cost)
		_on_unlock_upgrade(upgrade_idx)
		station_ui._on_disable_module_store() #i really dont know..... shouldnt do anything if not at a station because of 'if station' keywords in thingi fubhodgifaphjdlghruoetaifjpdvghruaeofisdh
	
	station_ui.player_balance = world.player.balance
	station_ui.player_SPL_upgrades_matrix = [world.player.current_SPL_upgrades, world.player.max_SPL_upgrades] #current, max
	station_ui.player_unlocked_upgrades = world.player.get_unlocked_upgrades()
	station_ui.update_upgrade_buttons()
	pass

func _on_refund_upgrade(upgrade_idx: playerAPI.UPGRADE_ID, refund: int) -> void:
	print("GAME: REFUNDING UPGRADE")
	if world.player.is_upgrade_unlocked(upgrade_idx):
		world.player.increaseBalance(refund)
		_on_lock_upgrade(upgrade_idx)
	
	station_ui.player_balance = world.player.balance
	station_ui.player_SPL_upgrades_matrix = [world.player.current_SPL_upgrades, world.player.max_SPL_upgrades] #current, max
	station_ui.player_unlocked_upgrades = world.player.get_unlocked_upgrades()
	station_ui.update_upgrade_buttons()
	pass

func _on_unlock_upgrade(upgrade_idx: playerAPI.UPGRADE_ID):
	var changed: bool = world.player.unlockUpgrade(upgrade_idx)
	if changed:
		_on_upgrade_state_change(upgrade_idx, true)
		#value change upgrade changes:
		match upgrade_idx:
			playerAPI.UPGRADE_ID.DRAG_DRIVES:
				world.player.speed += 1
				world.player.scanner_profile += 8.75
			playerAPI.UPGRADE_ID.IMPROVED_MAGNIFICATION:
				world.player.scopes_min_FOV -= 5
			playerAPI.UPGRADE_ID.ENHANCED_SCANNERS:
				world.player.scanner_power += 12.5
			playerAPI.UPGRADE_ID.STEALTH_COMPOSITES:
				world.player.scanner_profile -= 6.25
			playerAPI.UPGRADE_ID.REFINED_FUEL_FLOW:
				world.player.speed += 1
				world.player.scanner_profile += 25.0
			playerAPI.UPGRADE_ID.HEAT_SINK:
				world.player.scanner_profile -= 6.25
				world.player.speed -= 1
			playerAPI.UPGRADE_ID.OPTIMIZED_LIDAR:
				world.player.LIDAR_cooldown -= 1
	pass

func _on_lock_upgrade(upgrade_idx: playerAPI.UPGRADE_ID):
	var changed: bool = world.player.lockUpgrade(upgrade_idx)
	if changed:
		_on_upgrade_state_change(upgrade_idx, false)
		#value change upgrade changes:
		match upgrade_idx:
			playerAPI.UPGRADE_ID.DRAG_DRIVES:
				world.player.speed -= 1
				world.player.scanner_profile -= 8.75
			playerAPI.UPGRADE_ID.IMPROVED_MAGNIFICATION:
				world.player.scopes_min_FOV += 5
			playerAPI.UPGRADE_ID.ENHANCED_SCANNERS:
				world.player.scanner_power -= 12.5
			playerAPI.UPGRADE_ID.STEALTH_COMPOSITES:
				world.player.scanner_profile += 6.25
			playerAPI.UPGRADE_ID.REFINED_FUEL_FLOW:
				world.player.speed -= 1
				world.player.scanner_profile -= 25.0
			playerAPI.UPGRADE_ID.HEAT_SINK:
				world.player.scanner_profile += 6.25
				world.player.speed += 1
			playerAPI.UPGRADE_ID.OPTIMIZED_LIDAR:
				world.player.LIDAR_cooldown += 1
	pass

func _on_upgrade_state_change(upgrade_idx: playerAPI.UPGRADE_ID, state: bool):
	print("GAME: UPGRADE STATE CHANGED: ", upgrade_idx, " ", state)
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

func _on_increase_player_balance(amount: int) -> void: #shouldnt be used for anything besides debug...?
	world.player.increaseBalance(amount)
	pass

func _on_add_player_value(amount: int) -> void:
	world.player.addValue(amount)
	pass

func _on_remove_player_value(amount: int) -> void:
	world.player.removeValue(amount)
	pass

func _on_add_player_hull_stress(amount: int) -> void:
	#damage sfx, couldnt find any other place to put this :(
	if amount > 0:
		if world.player.hull_stress >= 100:
			get_tree().call_group("audioHandler", "play_once", load("uid://5di84fc8e1su"), -12, "SFX")
		else:
			get_tree().call_group("audioHandler", "play_once", load("uid://b31tkiiqdh72x"), -12, "SFX")
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
		if world.player.survived_mutiny == false:
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
	station_ui.player_balance = world.player.balance
	station_ui.player_hull_stress = world.player.hull_stress
	pass

func _on_open_pause_menu(full_pause: bool = true):
	if full_pause: pause_mode_handler._on_queue_pause_mode(game_data.PAUSE_MODES.PAUSE_MENU)
	else: pause_mode_handler._on_queue_pause_mode(game_data.PAUSE_MODES.QUICK_PAUSE)
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
	global_data.change_scene.emit("res://scenes/main-menu/main_menu.tscn")
	pass

func _on_exit_to_main_menu():
	global_data.change_scene.emit("res://scenes/main-menu/main_menu.tscn")
	pass

func _on_theorised_body(id: int):
	var body = world.player.current_star_system.get_body_from_identifier(id)
	if body: 
		_on_player_theorised_body(body)
	pass

func _on_tutorial_set_ingress_override(value: bool):
	var ingress = world.player.current_star_system.get_first_body_from_display_name("Ingress")
	if ingress != null:
		ingress.hidden = value
	pass

func _on_tutorial_set_omission_override(value: bool):
	var omission = world.player.current_star_system.get_first_body_from_display_name("Omission")
	if omission != null:
		omission.hidden = value
	pass

func _on_tutorial_player_win():
	_on_open_stats_menu(stats_menu.INIT_TYPES.TUTORIAL)
	pass

func _on_tutorial_enter_ingress(): #override for INGRESS, not a return value so i dont clog up _on_player_following_body
	#hard coded because i cant be fucking bothered
	var suno = world.get_system_from_identifier(1)
	var egress = suno.get_body_from_identifier(4)
	
	world.player.previous_star_system = world.player.current_star_system
	world.player.systems_traversed += 1
	
	_on_update_player_action_type(playerAPI.ACTION_TYPES.NONE, null)
	for body in suno.bodies:
		suno.updateBodyPosition(body.get_identifier(), get_physics_process_delta_time())
	world.player.position = egress.position
	world.player.setTargetPosition(world.player.position)
	world.player.updatePosition(get_physics_process_delta_time())
	
	#these have to be added BEFORE _on_switch_star_system for signal connections !
	suno.addRandomWeightedShip(egress)
	suno.addRandomWeightedShip(suno.get_planets().pick_random())
	suno.addRandomWeightedShip(suno.get_planets().pick_random())
	
	system_map._on_clear_console_entries()
	_on_switch_star_system(suno)
	barycenter_visualizer.locked_body_identifier = 0
	
	system_map.follow_body = null
	system_map.locked_body = null
	system_map.action_body = null
	
	wormhole_minigame.initialize(world.player.weirdness_index, world.player.hull_stress_wormhole)
	_on_wormhole_minigame_popup()
	_on_player_entering_system(suno)
	pass

func _on_tutorial_set_window_tutorials(value: bool) -> void:
	station_ui._on_set_tutorial_visible(value)
	wormhole_minigame._on_set_tutorial_visible(value)
	pass

func _on_tutorial_set_player_action_lock(value: bool) -> void:
	world.player.action_lock = value
	pass

func _on_tutorial_force_orbit_prelude() -> void:
	var system = world.player.current_star_system
	var prelude = system.get_first_body_from_display_name("Prelude")
	if prelude != null:
		_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, prelude)
	pass

func _on_tutorial_ingress_threshold_reached() -> void: #comes from system_map not dialogueManager! only _on_tutorial exception cos couldnt do it otherwise
	print("INGRESS THRESHOLD REACHED")
	var system = world.player.current_star_system
	var id = system.addUnitBody(
		interceptingUnitAPI.new(),
		starSystemAPI.BODY_TYPES.SHIP,
		system.identifier_count,
		game_data.get_random_starship_name(game_data.UNIT_AFFILIATIONS.MARAUDER),
		1,
		starSystemAPI.get_default_radius_solar_radii(),
		{"system": system, "player": world.player},
		{"affiliation": game_data.UNIT_AFFILIATIONS.MARAUDER, "hostile": true, "seed": randi()}
	)
	
	var marauder = system.get_body_from_identifier(id)
	var ingress = system.get_first_body_from_display_name("Ingress")
	
	if ingress != null:
		marauder.position = world.player.position + (world.player.position.direction_to(ingress.position) * (world.player.scanner_profile - 1))
	
	_on_reconnect_system_signals(system)
	
	get_tree().call_group("objectivesManager", "mark_category", "tutorialPostMarauderAppear", objectiveAPI.STATES.NONE)
	
	await get_tree().physics_frame
	_on_open_pause_menu(false)
	pass

func _on_tutorial_set_ui_stage(new_stage: String) -> void:
	print_debug("NEW UI STAGE: ", new_stage)
	match new_stage:
		"pre_prelude_theorise":
			system_map.barycenter_container.visible = false
			system_map.tabs_and_ca_scroll.visible = false
			system_map.status_control.visible = false
			system_map.scopes_bg.visible = false
		"pre_prelude_orbit":
			system_map.tabs_and_ca_scroll.visible = true
			system_map.scopes_bg.visible = true
		"pre_prelude_follow":
			pass
		"pre_ingress_theorise":
			system_map.status_control.visible = true
			system_map.barycenter_container.visible = true
		"pre_ingress_orbit":
			pass
	pass

func _on_add_player_morale(amount : int) -> void:
	world.player.addMorale(amount)
	pass

func _on_remove_player_morale(amount : int) -> void:
	world.player.removeMorale(amount)
	pass

func _on_stats_menu_quit(_init_type: int) -> void:
	if FileAccess.file_exists("user://stellar_cartographer_history.csv"):
		write_history(_init_type, FileAccess.ModeFlags.READ_WRITE)
	else:
		write_history(_init_type, FileAccess.ModeFlags.WRITE)
	
	match _init_type:
		stats_menu.INIT_TYPES.TUTORIAL:
			global_data.change_scene.emit("res://scenes/main-menu/main_menu.tscn")
		_:
			global_data.change_scene.emit("res://scenes/main-menu/main_menu.tscn") #WIN, DEATH
			game_data.deleteWorld()
	pass
func write_history(_init_type: int, mode: FileAccess.ModeFlags) -> void:
	var history = FileAccess.open("user://stellar_cartographer_history.csv", mode)
	history.seek_end()
	history.store_csv_line(PackedStringArray([
		ProjectSettings.get_setting("application/config/version"),
		world.player.name, 
		world.player.ship_name, 
		world.player.total_score, 
		world.player.systems_traversed, 
		stats_menu.INIT_TYPES.find_key(_init_type),
		roundi(world.play_time),
		world.player.analytics_exploration_data_payouts
	]))
	history.close()
	pass

func _on_player_data_value_changed(new_value: int):
	system_map._on_player_data_value_changed(new_value)
	pass

func _on_CME_time_current_updated(_time_current: float, _system_id: int):
	world.get_system_from_identifier(_system_id).system_hazard_metadata["CME_time_current"] = _time_current
	if _time_current <= 10:
		get_tree().call_group("audioHandler", "play_once", load("uid://bmx8m5qyt3ogy"), -24, "SFX")
	else:
		get_tree().call_group("audioHandler", "play_once", load("uid://c8lfpcf1vsiok"), -24, "SFX")
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
		
		if not world.player.is_invulnerable():
			_on_add_player_hull_stress(world.player.hull_stress_CME)
		get_tree().call_group("audioHandler", "play_once", load("uid://c7baaje1ffxh6"), 0.0, "SFX")
		get_tree().call_group("audioHandler", "plot_radio", load("uid://ddi2c1haas55w"))
		system_map._on_countdown_overlay_CME_flash()
	pass

func _on_player_in_pulsar_beam_cooldown_expired() -> void:
	if not world.player.is_invulnerable():
		_on_add_player_hull_stress(world.player.hull_stress_pulsar_beam)
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

func _on_update_player_in_pulsar_beam(player_in_pulsar_beam: bool):
	world.player.in_pulsar_beam = player_in_pulsar_beam
	pass

func _on_update_player_in_nebula(player_in_nebula: bool) -> void:
	world.player.in_nebula = player_in_nebula
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

func _on_roll_nav_buoy(_anomaly_seed: int) -> void: # i mean, technically its LEGAL?
	dialogue_manager._on_receive_nav_buoy_roll(world.roll_nav_buoy(_anomaly_seed))
	pass

func _on_supercharge_player_for_jumps(jumps: int):
	world.player.supercharge_jumps_remaining += jumps
	system_map.player_supercharged = world.player.supercharged #also updated when the player enters a new system
	pass

func _on_modify_character_standing(occupation: characterAPI.OCCUPATIONS, amount: int, _increase: bool):
	world.player.modifyCharacterStanding(occupation, amount, _increase)
	pass

func _on_play_civilized_system_leitmotif() -> void:
	if world.player.weirdness_index >= 0.2 and world.player.weirdness_index < 0.6: #in frontier
		if not world.played_frontier_leitmotif:
			get_tree().call_group("audioHandler", "queue_music", "res://sound/music/frontier_leitmotif.wav")
			world.played_frontier_leitmotif = true
			return
	elif world.player.weirdness_index >= 0.6: #in abyss
		if not world.played_abyss_leitmotif:
			get_tree().call_group("audioHandler", "queue_music", "res://sound/music/abyss_leitmotif.wav")
			world.played_abyss_leitmotif = true
			return
	#world.player.weirdness_index updates faster than game_data.player_weirdness index, and should thus be used all throughout game.gd
	
	get_tree().call_group("audioHandler", "queue_music", "res://sound/music/motif.tres")
	return

func _on_play_strange_discovery_theme_or_motif() -> void:
	if not world.played_strange_discovery_theme:
		get_tree().call_group("audioHandler", "queue_music", "res://sound/music/strange_discovery.ogg")
		world.played_strange_discovery_theme = true
	else:
		get_tree().call_group("audioHandler", "queue_music", "res://sound/music/strange_discovery_motif.ogg")
	pass

func _on_toggle_scope_mode_switch_button() -> void:
	system_3d._on_toggle_scope_mode_switch_button()
	pass

func _on_change_scope_mode(new_mode: playerAPI.SCOPE_MODES) -> void:
	system_3d.toggle_mode_switch_button_to_mode(new_mode)
	pass

func _on_player_scanner_contact_gained(_unit: unitBodyAPI) -> void:
	if not _unit.is_hidden():
		print_debug("GAME: PLAYER SCANNER CONTACT GAINED ", _unit)
		system_map._on_player_scanner_contact_gained(_unit)
		system_map._on_update_scanner_display_times(1.0, 1.0)
		if _unit is AIUnitAPI:
			if _unit.is_hostile():
				system_map._on_update_scanner_display_times(10.0, 1.0)
		get_tree().call_group("audioHandler", "play_once", load("uid://d1woqdnpk3xes"), -12.0, "SFX")
	pass

func _on_player_scanner_contact_lost(_unit: unitBodyAPI) -> void:
	if not _unit.is_hidden():
		print_debug("GAME: PLAYER SCANNER CONTACT LOST ", _unit)
		system_map._on_player_scanner_contact_lost(_unit)
		system_map._on_update_scanner_display_times(1.0, 1.0)
		get_tree().call_group("audioHandler", "play_once", preload("uid://qpsibe05f4su"), -12.0, "SFX")
	
	#dealing with deselecting the unit EVERYWHERE or else it can cause many errors bc it does not include is_theorised_not_known()
	#this definitely breaks a lot of rules, but i think its better to have it all centralised here!!!
	#its so ugly too... BLEGGHH. unfortunately, i cannot be bothered to make it prettier as i am NEVER touching it again :)
	
	if _unit == system_map.follow_body:
		system_map.follow_body = null
		system_map.reset_camera_follow_body()
	if _unit == system_map.follow_body_modifier:
		system_map.follow_body_modifier = null
		system_map.reset_camera_follow_body()
	if _unit == system_map.locked_body:
		system_map.locked_body = null
		#system_map.emit_signal("lockedBodyDepreciated") <- all this does is reset system_3d label_locked_body_identifier, which is useless!!!
	if _unit == system_map.action_body:
		system_map._on_stop_button_pressed()
	
	if _unit.get_identifier() == system_3d.locked_body_identifier \
	or _unit.get_identifier() ==  system_3d.label_locked_body_identifier:
		system_3d.reset_locked_body()
	
	if _unit.get_identifier() == barycenter_visualizer.locked_body_identifier:
		barycenter_visualizer.locked_body_identifier = 0
	pass

func _on_unit_play_sound(_path: String, _volume_db: float, _bus: StringName, _u: unitBodyAPI) -> void:
	get_tree().call_group("audioHandler", "play_once", load(_path), _volume_db, _bus)
	pass

func _on_mine_detonated(id: int) -> void: #starSystemAPI signal
	system_3d._on_mine_detonated(id) #plays directional SFX
	get_tree().call_group("audioHandler", "plot_radio", load("uid://b56k7w734n8kd"))
	pass

func _on_body_removed(id: int) -> void: #starSystemAPI signal
	system_3d._on_body_removed(id)
	pass

func _on_document_ping_hit_status(hit: bool) -> void:
	if hit:
		world.player.sys_survey_hit_pings += 1
		world.player.sys_survey_total_pings += 1
	else:
		world.player.sys_survey_total_pings += 1
	pass

func _on_sys_survey_efficiency_bonus() -> void:
	var base: int = world.player.sys_survey_value * 0.25
	var reward = base
	var time_seconds: float = world.play_time - world.player.sys_survey_time_start
	var time_minutes: float = time_seconds / 60
	
	reward *= world.player.sys_survey_ping_ratio
	
	if time_minutes > 5.0: # 5 minutes * 25 systems = basically 2 hours. so if people are spending more than 5 minutes in a system, then thats bad
		reward /= time_minutes - 4.0 #e.g 6 minutes would divide the score by 2, 7 minutes by 3 etc
	
	world.player.current_value += roundi(reward)
	
	var ratio = float(reward) / float(base)
	
	print_debug("GAME: SYSTEM SURVEY EFFICIENCY BONUS: %d (BASE: %d , PING RATIO: %f , MINUTES: %f)" % [reward, base, world.player.sys_survey_ping_ratio, time_minutes])
	
	var console_base_secs = roundi(time_seconds)
	var console_secs = console_base_secs % 60
	var console_mins = (console_base_secs / 60) % 60
	
	_on_add_console_entry("SYSTEM SURVEY EFFICIENCY BONUS: +%d%c (%.1f%%) (%dm %ds)" % [reward, "ň", ratio * 100.0, console_mins, console_secs], Color.GREEN)
	get_tree().call_group("audioHandler", "play_once", load("uid://dg602vfmho6fq"), 0.0, "SFX")
	pass

func _on_add_character_xp(occupation: characterAPI.OCCUPATIONS, amount: int) -> void:
	world.player.addCharacterXP(occupation, amount)
	pass

func _on_remove_character_initiative_xp(occupation: characterAPI.OCCUPATIONS) -> void:
	world.player.removeCharacterInitiativeXP(occupation)
	pass

func _on_proximity_blinker_condition_changed(active: bool, last_condition_time: float) -> void:
	if active and (last_condition_time > 60.0):
		_on_add_console_entry("Proximity warning.", Color.RED)
	pass

func _on_insa_make_all_wormholes_revealable() -> void:
	var current = world.player.current_star_system
	if current.special_system_classification == game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.INSA:
		for wormhole in current.get_bodies_of_body_type(starSystemAPI.BODY_TYPES.WORMHOLE):
			wormhole.hidden = false
	pass

func _on_insa_make_rift_driver_unavailable() -> void:
	var custom_bodies = world.player.current_star_system.get_bodies_of_body_type(starSystemAPI.BODY_TYPES.CUSTOM)
	for body in custom_bodies:
		if body.get_dialogue_tag() == "insaRiftDriver":
			body.metadata["custom_available"] = false
	pass

func _on_insa_make_military_ships_neutral() -> void:
	var ship_bodies = world.player.current_star_system.get_bodies_of_body_type(starSystemAPI.BODY_TYPES.SHIP)
	for body in ship_bodies:
		if body.metadata.get("affiliation") in [game_data.UNIT_AFFILIATIONS.INSA_MILITARY_A, game_data.UNIT_AFFILIATIONS.INSA_MILITARY_B]:
			body.metadata["hostile"] = false
			body.metadata["ship_available"] = false
	pass

func _on_open_LRS():
	await get_tree().physics_frame
	var following_body = world.player.action_body #should be set as playerAPI setting action_body calls _on_player_following_body, which calls dialogue, which calls this.
	if world.player.is_upgrade_unlocked(world.player.UPGRADE_ID.LONG_RANGE_SCOPES):
		long_range_scopes._on_current_entity_changed(following_body)
		
		if world.player.discovered_entities.find(following_body.entity_classification) == -1:
			world.player.discovered_entities.append(following_body.entity_classification)
		lrs_bestiary.set("discovered_entities_matrix", world.player.discovered_entities)
		lrs_bestiary._on_current_entity_changed(following_body)
		
		if not $long_range_scopes_window.is_visible():
			_on_long_range_scopes_popup()
	pass

func _on_open_GLS():
	await get_tree().physics_frame
	var following_body = world.player.action_body #should be set as playerAPI setting action_body calls _on_player_following_body, which calls dialogue, which calls this.
	if world.player.is_upgrade_unlocked(world.player.UPGRADE_ID.GAS_LAYER_SURVEYOR):
		gas_layer_surveyor._on_current_planet_changed(following_body)
		for tag in gas_layer_surveyor.current_layers:
			var idx = gas_layer_surveyor.layer_data.keys().find(tag)
			if world.player.discovered_gas_layers.find(idx) == -1:
				world.player.discovered_gas_layers.append(idx)
		if not $gas_layer_surveyor_window.is_visible():
			_on_gas_layer_surveyor_popup()
	pass



#handshake between game.gd and pauseModeHandler.gd
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
	
	#system_map.reset_player_boosting() #to stop boosting from being stuck to true, this SHOULD cover ALL grounds! #removed 10/7/26
	system_map.reset_actions_buttons_pressed() #godot 4.3 migration quick fix
	pass




func _on_DEBUG_clear_load_rules() -> void:
	dialogue_manager.clear_and_load_rules()
	pass

func _on_DEBUG_reveal_all_wormholes() -> void:
	for body in world.player.current_star_system.bodies:
		if body.get_type() == starSystemAPI.BODY_TYPES.WORMHOLE:
			body.known = true
	pass

func _on_DEBUG_reveal_all_bodies() -> void:
	for body in world.player.current_star_system.bodies:
		body.known = true
	pass

func _on_DEBUG_force_quit_dialogue() -> void:
	dialogue_manager.closeDialog()
	pass

func _on_DEBUG_force_unexplored_system() -> void:
	var new = _on_create_new_star_system()
	new.createAuxiliaryUnexplored(world.player.speed)
	_on_switch_star_system(new)
	_on_player_entering_system(new)
	_on_DEBUG_reveal_all_bodies()
	
	# test 100 star systems for factor(s) \/
	#var star_hook_counts: Array[int] = []
	#var sa_counts: Array[int] = []
	#for i in 100:
	#	var star_hook_count: int = 0
	#	var sa_count: int = 0
	#	
	#	var new = _on_create_new_star_system()
	#	new.createAuxiliaryUnexplored(world.player.speed)
	#	for b in new.bodies:
	#		if b.get_type() == starSystemAPI.BODY_TYPES.SPACE_ANOMALY:
	#			sa_count += 1
	#		if b is orbitBodyAPI:
	#			if b.hook_identifier == new.get_first_star().get_identifier():
	#				star_hook_count += 1
	#	star_hook_counts.append(star_hook_count)
	#	sa_counts.append(sa_count)
	#
	#var sum_func = func(accum, number):
	#	return accum + number
	#
	#print(star_hook_counts)
	#print(sa_counts)
	#
	#var analytics_avg_star_hook_count: float = float(star_hook_counts.reduce(sum_func, 0)) / star_hook_counts.size()
	#var analytics_avg_sa_count: float = float(sa_counts.reduce(sum_func, 0)) / sa_counts.size()
	#
	#print(analytics_avg_star_hook_count)
	#print(analytics_avg_sa_count)
	pass

func _on_DEBUG_max_character_standing() -> void:
	_on_modify_character_standing(characterAPI.OCCUPATIONS.FIRST_OFFICER, 100, true)
	_on_modify_character_standing(characterAPI.OCCUPATIONS.CHIEF_ENGINEER, 100, true)
	_on_modify_character_standing(characterAPI.OCCUPATIONS.SECURITY_OFFICER, 100, true)
	_on_modify_character_standing(characterAPI.OCCUPATIONS.MEDICAL_OFFICER, 100, true)
	pass

func _on_DEBUG_quick_traverse() -> void:
	var adjusted_wormholes = world.player.current_star_system.get_wormholes()
	var to_erase: Array = []
	for w in adjusted_wormholes:
		var destination = w.destination_system
		if destination == world.player.previous_star_system or w.is_disabled():
			to_erase.append(w)
	for w in to_erase:
		adjusted_wormholes.erase(w)
	var final_wormhole = adjusted_wormholes.pick_random()
	enter_wormhole(final_wormhole, world.player.current_star_system.get_wormholes(), final_wormhole.destination_system, true)
	pass

func _on_DEBUG_regenerate_system_3d() -> void:
	system_3d.regenerate_system()
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
