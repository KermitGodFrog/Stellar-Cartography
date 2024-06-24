extends Resource
class_name worldAPI

var star_systems: Array[starSystemAPI]
var player: playerAPI
var identifier_count: int = 1

func createStarSystem(d_name: String):
	var new_system = starSystemAPI.new()
	new_system.set_identifier(identifier_count)
	identifier_count += 1
	new_system.set_display_name(d_name)
	star_systems.append(new_system)
	return new_system

func removeStarSystem(id: int):
	for system in star_systems:
		if system.get_identifier() == id:
			star_systems.erase(system.get_identifier())
			break
	pass

func createPlayer(speed: int, max_jumps: int):
	var new_player = playerAPI.new()
	new_player.speed = speed
	new_player.max_jumps = max_jumps
	player = new_player
	return new_player

func get_system_from_identifier(id: int):
	var get_system: starSystemAPI
	for system in star_systems:
		if system.get_identifier() == id:
			get_system = system
			break
	return get_system
