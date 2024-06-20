extends Node
#Handles most game stuff that is not local to child windows, loads data, saves data, the whole thing. child windows must route data through this to change the world/system/player

var world: worldAPI
@onready var system_map = $system_window/system
@onready var system_3d = $system_3d_window/system_3d
@onready var sonar = $sonar_window/sonar_control
@onready var console_control = $console_control

func createWorld():
	world = worldAPI.new()
	pass

func _ready():
	system_map.connect("updatePlayerTargetPosition", _on_update_player_target_position)
	system_map.connect("updateTargetPosition", _on_update_target_position)
	system_map.connect("updatedLockedBody", _on_locked_body_updated)
	
	system_3d.connect("foundBody", _on_found_body)
	system_3d.connect("addConsoleItem", _on_add_console_item)
	
	sonar.connect("sonarPing", _on_sonar_ping)
	
	console_control.connect("systemMapPopup", _on_system_map_popup)
	console_control.connect("system3DPopup", _on_system_3d_popup)
	console_control.connect("sonarPopup", _on_sonar_popup)
	
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
	world.createPlayer(3)
	
	#new game stuff
	var new = _on_create_new_star_system(false)
	for i in range(2):
		_on_create_new_star_system(false, new)
	new.generateRandomWormholes()
	_on_switch_star_system(new)
	pass

func _physics_process(delta):
	#updating positions of everyhthing for API's
	world.player.updatePosition(delta)
	var current_bodies = world.player.current_star_system.bodies
	if current_bodies:
		for body in current_bodies:
			world.player.current_star_system.updateBodyPosition(body.get_identifier(), delta)
	
	#switching system if close enough to wormhole  (dont thinkj anything else can have jusrisdiction - no API other than the player should be aware of the player)
	var wormholes = world.player.current_star_system.get_wormholes()
	for wormhole in wormholes: # ^^^ all wormholes in current star system dont worry 
		if world.player.position.distance_to(wormhole.position) < (20.0 * wormhole.radius) and not wormhole.is_disabled:
			print("GAME: (DEBUG) SWITCHING STAR SYSTEMS")
			var destination = wormhole.destination_system
			if destination:
				#spawning new wormholes in destination system if nonexistent
				if not destination.destination_systems:
					for i in range(2):
						_on_create_new_star_system(false, destination)
					destination.generateRandomWormholes()
				
				var destination_position: Vector2 = Vector2.ZERO
				var destination_wormhole = destination.get_wormhole_with_destination_system(world.player.current_star_system)
				if destination_wormhole:
					destination.updateBodyPosition(destination_wormhole.get_identifier(), delta) #REQURIED SO WORMHOLE HAVE A POSITION OTHER THAN 0,0
					destination_position = destination_wormhole.position
					destination_wormhole.is_known = true
				
				world.player.position = destination_position
				_on_switch_star_system(destination)
	
	#updating positions of everyhthing for windows
	system_map.set("player_position_matrix", [world.player.position, world.player.target_position])
	system_3d.set("player_position", world.player.position)
	pass

func _on_update_player_target_position(pos: Vector2, slowdown: bool = true):
	world.player.target_position = pos
	world.player.slowdown = slowdown
	print("SYSTEM MAP: UPDATING PLAYER TARGET POSITION: ", pos)
	pass

func _on_update_target_position(pos: Vector2):
	system_3d.set("target_position", pos)
	print("SYSTEM MAP: UPDATING TARGET POSITION: ", pos)
	pass

func _on_create_new_star_system(force_switch_before_post_gen: bool = false, for_system: starSystemAPI = null):
	var system = world.createStarSystem("yooooooo")
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
	world.player.current_star_system = to_system
	system_map.system = to_system
	system_3d.system = to_system
	system_3d.spawnBodies()
	system_3d.reset_locked_body()
	return to_system

func _on_locked_body_updated(body: bodyAPI):
	system_3d.set("locked_body_identifier", body.get_identifier())
	system_3d.set("target_position", Vector2.ZERO)
	pass

func _on_found_body(id: int):
	var system = world.get_system_from_identifier(world.player.current_star_system.get_identifier())
	if system:
		var body = system.get_body_from_identifier(id)
		if body:
			body.is_known = true
			if body.metadata.has("value"): world.player.current_value += body.metadata.get("value")
			var sub_bodies = system.get_bodies_with_hook_identifier(id)
			if sub_bodies:
				for sub_body in sub_bodies:
					if sub_body.is_asteroid_belt():
						sub_body.is_known = true
	pass

func _on_add_console_item(text: String, bg_color: Color = Color.WHITE):
	console_control.add_console_item(text, bg_color)
	pass

func _on_sonar_ping(ping_width: int, ping_length: int, ping_direction: Vector2):
	print("SONAR INTERFACE (DEBUG): PINGING")
	system_map._on_sonar_ping(ping_width, ping_length, ping_direction)
	pass



func _on_system_map_popup():
	$system_window.popup()
	pass

func _on_system_3d_popup():
	$system_3d_window.popup()
	pass

func _on_sonar_popup():
	$sonar_window.popup()
	pass
