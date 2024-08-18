extends Node
#Handles most game stuff that is not local to child windows, loads data, saves data, the whole thing. child windows must route data through this to change the world/system/player

var world: worldAPI
@onready var system_map = $system_window/system
@onready var system_3d = $system_3d_window/system_3d
@onready var sonar = $sonar_window/sonar_control
@onready var barycenter_visualizer = $barycenter_visualizer_window/barycenter_control
@onready var audio_visualizer = $audio_visualizer_window/audio_control
@onready var station_ui = $station_window/station_control
@onready var dialogue_manager = $dialogueManager

func createWorld():
	world = worldAPI.new()
	pass

func _ready():
	system_map.connect("updatePlayerActionType", _on_update_player_action_type)
	system_map.connect("updatePlayerTargetPosition", _on_update_player_target_position)
	system_map.connect("updateTargetPosition", _on_update_target_position)
	system_map.connect("updatedLockedBody", _on_locked_body_updated)
	system_map.connect("lockedBodyDepreciated", _on_locked_body_depreciated)
	system_map.connect("DEBUG_REVEAL_ALL_WORMHOLES", _ON_DEBUG_REVEAL_ALL_WORMHOLES)
	system_map.connect("DEBUG_REVEAL_ALL_BODIES", _ON_DEBUG_REVEAL_ALL_BODIES)
	
	system_3d.connect("foundBody", _on_found_body)
	system_3d.connect("addConsoleItem", _on_add_console_item)
	
	sonar.connect("sonarPing", _on_sonar_ping)
	
	station_ui.connect("sellExplorationData", _on_sell_exploration_data)
	station_ui.connect("undockFromStation", _on_undock_from_station)
	station_ui.connect("upgradeShip", _on_upgrade_ship)
	station_ui.connect("addSavedAudioProfile", _on_add_saved_audio_profile)
	
	audio_visualizer.connect("removeSavedAudioProfile", _on_remove_saved_audio_profile)
	
	system_map.connect("system3DPopup", _on_system_3d_popup)
	system_map.connect("sonarPopup", _on_sonar_popup)
	system_map.connect("barycenterPopup", _on_barycenter_popup)
	system_map.connect("audioVisualizerPopup", _on_audio_visualizer_popup)
	
	dialogue_manager.connect("addPlayerValue", _on_add_player_value)
	#var error = game_data.loadWorld()
	#if error is worldAPI:
		#print("SAVE FILE LOADED")
		#world = error
	#else:
		#print("NO SAVE FILE!")
		#createWorld()
		#world.createPlayer(1)
		#
		#new game stuff
		#var new = _on_create_new_star_system(false)
		#for i in range(2):
		#	_on_create_new_star_system(false, new)
		#new.generateRandomWormholes()
		#_on_switch_star_system(new)
	
	createWorld()
	world.createPlayer(3, 3, 10)
	world.player.resetJumpsRemaining()
	
	#CHARACTERS FOR ROGUELIKE:
	world.player.first_officer = load("res://Data/Characters/rui.tres")
	world.player.chief_engineer = load("res://Data/Characters/jiya.tres")
	world.player.security_officer = load("res://Data/Characters/walker.tres")
	world.player.medical_officer = load("res://Data/Characters/febris.tres")
	
	world.player.connect("orbitingBody", _on_player_orbiting_body)
	world.player.connect("followingBody", _on_player_following_body)
	
	#new game stuff
	var new = _on_create_new_star_system(false)
	for i in range(2):
		_on_create_new_star_system(false, new)
	new.generateRandomWormholes()
	_on_switch_star_system(new)
	
	_on_unlock_upgrade(playerAPI.UPGRADE_ID.ADVANCED_SCANNING)
	_on_unlock_upgrade(playerAPI.UPGRADE_ID.AUDIO_VISUALIZER)
	
	_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, new.get_first_star())
	
	#await get_tree().create_timer(1.0, true).timeout
	
	#var new_query = responseQuery.new()
	#new_query.add("concept", "openDialog")
	#new_query.add("id", "station")
	#new_query.add_tree_access("station_classification", str("ABANDONED"))
	#new_query.add_tree_access("is_station_abandoned", true)
	#new_query.add_tree_access("is_station_inhabited", false)
	#get_tree().call_group("dialogueManager", "speak", self, new_query)
	
	#var new_query = responseQuery.new()
	#new_query.add("concept", "randomPAOpenDialog")
	#get_tree().call_group("dialogueManager", "speak", self, new_query)
	pass

func _physics_process(delta):
	#CORE GAME LOGIC \/\/\/\/\/
	#updating positions of everyhthing for API's
	world.player.updateActionBodyState()
	world.player.updatePosition(delta)
	var current_bodies = world.player.current_star_system.bodies
	if current_bodies:
		for body in current_bodies:
			world.player.current_star_system.updateBodyPosition(body.get_identifier(), delta)
	
	#updating positions of everyhthing for windows
	system_map.set("player_position_matrix", [world.player.position, world.player.target_position])
	system_3d.set("player_position", world.player.position)
	station_ui.set("player_saved_audio_profiles_size_matrix", [world.player.saved_audio_profiles.size(), world.player.max_saved_audio_profiles])
	audio_visualizer.set("saved_audio_profiles_size_matrix", [world.player.saved_audio_profiles.size(), world.player.max_saved_audio_profiles])
	audio_visualizer.set("saved_audio_profiles", world.player.saved_audio_profiles)
	
	dialogue_manager.set("player", world.player)
	
	#SETTING WHETHER SYSTEM MAP HAS FOCUS OR NOT (SINCE ITS A NODE IT CANNOT USE HAS_FOCUS() DIRECTLY!)
	if $system_3d_window.has_focus() or $sonar_window.has_focus() or $barycenter_visualizer_window.has_focus() or $audio_visualizer_window.has_focus() or $station_window.has_focus(): system_map.has_focus = false
	else: system_map.has_focus = true
	pass

func _on_player_orbiting_body(orbiting_body: bodyAPI):
	pass

func _on_player_following_body(following_body: bodyAPI):
	if following_body is wormholeAPI:
		var following_wormhole = following_body #so its not confusing
		var wormholes = world.player.current_star_system.get_wormholes()
		var destination = following_wormhole.destination_system
		
		if destination and (not destination == world.player.previous_star_system):
			
			var new_query = responseQuery.new()
			new_query.add("concept", "openDialog")
			new_query.add("id", "wormhole")
			get_tree().call_group("dialogueManager", "speak", self, new_query)
			
			var RETURN_STATE = await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
			match RETURN_STATE:
				"ENTER_WORMHOLE":
					enter_wormhole(following_wormhole, wormholes, destination)
				_:
					_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_wormhole)
	
	if following_body is stationAPI:
		var following_station = following_body
		
		var is_station_abandoned: bool = following_station.station_classification in [game_data.STATION_CLASSIFICATIONS.ABANDONED, game_data.STATION_CLASSIFICATIONS.ABANDONED_BACKROOMS, game_data.STATION_CLASSIFICATIONS.ABANDONED_OPERATIONAL, game_data.STATION_CLASSIFICATIONS.COVERUP, game_data.STATION_CLASSIFICATIONS.PARTIALLY_SALVAGED]
		var is_station_inhabited: bool = following_station.station_classification in [game_data.STATION_CLASSIFICATIONS.STANDARD, game_data.STATION_CLASSIFICATIONS.PIRATE]
		
		var new_query = responseQuery.new()
		new_query.add("concept", "openDialog")
		new_query.add("id", "station")
		new_query.add_tree_access("station_classification", str(game_data.STATION_CLASSIFICATIONS.find_key(following_station.station_classification)))
		new_query.add_tree_access("is_station_abandoned", is_station_abandoned)
		new_query.add_tree_access("is_station_inhabited", is_station_inhabited)
		get_tree().call_group("dialogueManager", "speak", self, new_query)
		
		var RETURN_STATE = await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
		match RETURN_STATE:
			"DOCK_WITH_STATION":
				dock_with_station(following_station)
			_:
				_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_station)
	
	if following_body.is_planet():
		var following_planet = following_body
		if following_planet.metadata.get("has_planetary_anomaly", false) == true:
			if following_planet.metadata.get("is_planetary_anomaly_available", false) == true:
				
				var new_query = responseQuery.new()
				new_query.add("concept", "randomPAOpenDialog")
				new_query.add("planet_classification", following_planet.metadata.get("planet_classification"))
				new_query.add_tree_access("planet_name", following_planet.display_name)
				get_tree().call_group("dialogueManager", "speak", self, new_query)
				
				var RETURN_STATE = await get_tree().get_first_node_in_group("dialogueManager").onCloseDialog
				match RETURN_STATE:
					"HARD_LEAVE":
						following_planet.metadata["is_planetary_anomaly_available"] = false
						_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_planet)
					"SOFT_LEAVE":
						following_planet.metadata["is_planetary_anomaly_available"] = true
						_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_planet)
					_:
						_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, following_planet)
	pass

func enter_wormhole(following_wormhole, wormholes, destination):
	#spawning new wormholes in destination system if nonexistent
	if not destination.destination_systems:
		for i in range(2):
			_on_create_new_star_system(false, destination)
		destination.generateRandomWormholes()
	
	#var destination_position: Vector2 = Vector2.ZERO
	var destination_wormhole = destination.get_wormhole_with_destination_system(world.player.current_star_system)
	if destination_wormhole:
		#destination.updateBodyPosition(destination_wormhole.get_identifier(), delta) #REQURIED SO WORMHOLE HAVE A POSITION OTHER THAN 0,0
		#destination_position = destination_wormhole.position
		#_on_update_player_action_type(playerAPI.ACTION_TYPES.ORBIT, destination_wormhole)
		destination_wormhole.is_known = true
		#system_3d.locked_body_identifier = destination_wormhole.get_identifier() #diesnt seem to work?!
	
	#setting whether the new system is a civilized system or not
	world.player.removeJumpsRemaining(1) #removing jumps remaining until reaching a civilized system
	if world.player.get_jumps_remaining() == 0:
		destination.generateRandomWeightedStations()
		world.player.resetJumpsRemaining()
		for body in destination.bodies:
			body.is_known = true
	
	#world.player.position = destination_position
	world.player.target_position = world.player.position
	system_map._on_start_movement_lock_timer()
	
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
		station_ui.has_sold_previously = false #allowing to sell exploration data at station at next civilized system
	
	if destination_wormhole: world.player.position = destination_wormhole.position
	world.player.previous_star_system = world.player.current_star_system
	world.player.systems_traversed += 1
	_on_switch_star_system(destination)
	pass

func dock_with_station(following_station):
	station_ui.station = following_station
	station_ui.player_current_value = world.player.current_value
	station_ui.player_balance = world.player.balance
	
	var pending_audio_profiles = []
	for s in world.star_systems:
		if s != world.player.current_star_system:
			for b in s.bodies:
				if (b.get_current_variation() != null and b.get_guessed_variation() != null) and b.is_planet():
					var helper = audioProfileHelper.new()
					var mix = s.planet_type_audio_data.get(b.metadata.get("planet_type")).get(b.get_guessed_variation())
					helper.mix = mix
					helper.body = b
					pending_audio_profiles.append(helper)
	station_ui.pending_audio_profiles.append_array(pending_audio_profiles)
	
	_on_station_popup()
	pass





func _on_update_player_action_type(type: playerAPI.ACTION_TYPES, action_body):
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
	system.generateRandomWeightedBodies(hook_star)
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
	system_3d.spawnBodies()
	system_3d.reset_locked_body()
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
	var system = world.get_system_from_identifier(world.player.current_star_system.get_identifier())
	if system:
		var body = system.get_body_from_identifier(id)
		if body:
			body.is_known = true
			if body.metadata.has("value"): world.player.current_value += body.metadata.get("value")
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
	pass

func _on_sell_exploration_data(sell_percentage_of_market_price: int):
	print("STATION_UI (DEBUG): SELLING EXPLORATION DATA")
	var multiplier = sell_percentage_of_market_price / 100.0
	var sell_for = world.player.current_value * multiplier
	#NEED TO ADD MONEY FOR GUESSING CORRECT PLANET VARIATIONS!!!!
	
	for s in world.star_systems: for b in s.bodies:
		if b.guessed_variation and b.current_variation:
			if b.guessed_variation == b.current_variation:
				var value = b.metadata.get("value")
				if value: sell_for += value #2x planet payout for guessing correct planet variation
	
	world.player.increaseBalance(sell_for)
	world.player.current_value = 0
	station_ui.player_balance = world.player.balance
	pass

func _on_upgrade_ship(upgrade_idx: playerAPI.UPGRADE_ID, cost: int):
	print("STATION_UI (DEBUG): UPGRADING SHIP")
	if world.player.balance >= cost and (world.player.get_upgrade_unlocked_state(upgrade_idx) != true):
		world.player.decreaseBalance(cost)
		_on_unlock_upgrade(upgrade_idx)
	pass

func _on_undock_from_station(from_station: stationAPI):
	print("STATION_UI (DEBUG): UNDOCKING FROM STATION")
	$station_window.hide()
	$interaction_cooldown.start()
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
	pass

func _on_add_player_value(amount: int) -> void:
	world.player.current_value += amount
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






func _on_system_3d_popup():
	$system_3d_window.popup()
	_on_add_console_item("Opening scopes.", Color("353535"), 50)
	pass

func _on_sonar_popup():
	$sonar_window.popup()
	_on_add_console_item("Opening LIDAR.", Color("353535"), 50)
	pass

func _on_barycenter_popup():
	$barycenter_visualizer_window.popup()
	_on_add_console_item("Opening barycenter visualizer.", Color("353535"), 50)
	pass

func _on_audio_visualizer_popup():
	audio_visualizer._on_popup()
	$audio_visualizer_window.popup()
	_on_add_console_item("Opening audio visualizer.", Color("353535"), 50)
	pass

func _on_station_popup():
	$station_window.popup()
	get_tree().paused = true
	pass
