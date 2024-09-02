extends Resource
class_name worldAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

@export var star_systems: Array[starSystemAPI]
@export var player: playerAPI
@export var identifier_count: int = 1
@export var dialogue_memory: Dictionary = {}

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
			star_systems.erase(system)
			break
	pass

func createPlayer(speed: int, max_jumps: int, max_saved_audio_profiles: int):
	var new_player = playerAPI.new()
	new_player.speed = speed
	new_player.max_jumps = max_jumps
	new_player.max_saved_audio_profiles = max_saved_audio_profiles
	player = new_player
	return new_player


func get_system_from_identifier(id: int):
	var get_system: starSystemAPI
	for system in star_systems:
		if system.get_identifier() == id:
			get_system = system
			break
	return get_system

func get_systems_excluding_system(exclude_system: starSystemAPI):
	var return_systems: Array[starSystemAPI] = []
	for system in star_systems:
		if system != exclude_system:
			return_systems.append(system)
	return return_systems

func remove_systems_excluding_systems(exclude_systems: Array[starSystemAPI]):
	var remove_systems: Array[starSystemAPI] = []
	for system in star_systems:
		var is_in_exclude_systems: bool = false
		for exclude_system in exclude_systems:
			if exclude_system == system:
				is_in_exclude_systems = true
		
		if not is_in_exclude_systems:
			remove_systems.append(system)
	
	for system in remove_systems:
		removeStarSystem(system.get_identifier())
	pass
