extends Node
#Handles most game stuff that is not local to child windows, loads data, saves data, the whole thing. child windows must route data through this to change the world/system/player

var world: worldAPI
@onready var system_map = $system_window/system
@onready var system_3d = $system_3d_window/system_3d
@onready var console_control = $console_control

func createWorld():
	world = worldAPI.new()
	pass

func loadWorld():
	pass

func _ready():
	system_map.connect("updatePlayerTargetPosition", _on_update_player_target_position)
	system_map.connect("updateTargetPosition", _on_update_target_position)
	system_map.connect("debugCreateNewStarSystem", _on_create_new_star_system)
	system_map.connect("updatedLockedBody", _on_locked_body_updated)
	
	system_3d.connect("foundBody", _on_found_body)
	system_3d.connect("addConsoleItem", _on_add_console_item)
	
	console_control.connect("systemMapPopup", _on_system_map_popup)
	console_control.connect("system3DPopup", _on_system_3d_popup)
	console_control.connect("sonarPopup", _on_sonar_popup)
	
	
	#creates new world or loads previous world, creates new system or loads old system
	createWorld()
	world.createPlayer(1) #player params should be set if theres a save file or smthn
	
	#new system, under match conditions later if no save file is being loaded
	var new = _on_create_new_star_system(false)
	for i in range(2):
		_on_create_new_star_system(false, new)
	new.generateRandomWormholes()
	_on_switch_star_system(new)
	
	#var system = world.createStarSystem("yooooo")
	#var hook_star = system.createRandomWeightedPrimaryHookStar()
	#system.generateRandomWeightedBodies(hook_star)
	#world.player.current_star_system = system
	#system_map.system = system
	pass

func _physics_process(delta):
	world.player.updatePosition(delta)
	var current_bodies = world.player.current_star_system.bodies
	if current_bodies:
		for body in current_bodies:
			world.player.current_star_system.updateBodyPosition(body.get_identifier(), delta)
	
	#switching system if close enough to wormhole  (dont thinkj anything else can have jusrisdiction - no API other than the player should be aware of the player)
	var wormholes = world.player.current_star_system.get_wormholes()
	for wormhole in wormholes: # ^^^ all wormholes in current star system dont worry 
		if world.player.position.distance_to(wormhole.position) < (2 * wormhole.radius):
			print("GAME: (DEBUG) SWITCHING STAR SYSTEMS")
			var destination = wormhole.destination_system
			if destination:
				if not destination.destination_systems:
					for i in range(2):
						_on_create_new_star_system(false, destination)
					destination.generateRandomWormholes()
				_on_switch_star_system(destination)
				world.player.position = Vector2.ZERO #resetting player pos
				world.player.target_position = Vector2.ZERO #resetting player target pos
	
	system_map.set("player_position_matrix", [world.player.position, world.player.target_position])
	system_3d.set("player_position", world.player.position)
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
	var system = world.createStarSystem("yooooooo")
	var hook_star = system.createRandomWeightedPrimaryHookStar()
	system.generateRandomWeightedBodies(hook_star)
	if for_system: for_system.destination_systems.append(system)
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
	pass

func _on_add_console_item(text: String, bg_color: Color = Color.WHITE):
	console_control.add_console_item(text, bg_color)
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
