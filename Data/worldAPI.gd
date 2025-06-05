extends Resource
class_name worldAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

@export var star_systems: Array[starSystemAPI]
@export var player: playerAPI
@export_storage var identifier_count: int = 1

@export var dialogue_memory: Dictionary = {}
@export var objectives: Dictionary = {}

#KEY CUSTOMIZATION
@export var _total_systems: int 
@export var _max_jumps: int
@export var _hull_stress_wormhole: int
@export var _hull_stress_CME: int

@export var SA_chance_per_candidate: float
@export var PA_chance_per_planet: float
@export var missing_AO_chance_per_planet: float
# in order to justify why thsi is here - what if the player wants to update key customization while playing? this would be useful to ahndle it

func createStarSystem(d_name: String) -> starSystemAPI:
	var new_system = starSystemAPI.new()
	new_system.name_scheme = game_data.NAME_SCHEMES.values().pick_random()
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

func createPlayer(name: String, prefix: String) -> playerAPI:
	var new_player = playerAPI.new()
	new_player.name = name
	new_player.prefix = prefix
	
	new_player.max_jumps = _max_jumps
	new_player.total_systems = _total_systems
	new_player.hull_stress_wormhole = _hull_stress_wormhole
	new_player.hull_stress_CME = _hull_stress_CME
	
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

func get_pending_audio_profiles() -> Array[audioProfileHelper]:
	var pending_audio_profiles: Array[audioProfileHelper] = []
	for s in star_systems:
		for b in s.bodies:
			if b.get_type() == starSystemAPI.BODY_TYPES.PLANET:
				if ((b.get_current_variation() != -1) and (b.get_guessed_variation() != -1)):
					if b.metadata.get("has_valid_audio_profile", true) == true:
						var helper = audioProfileHelper.new()
						var mix = s.planet_type_audio_data.get(b.metadata.get("planet_type")).get(b.get_guessed_variation())
						helper.mix = mix
						helper.body = b
						pending_audio_profiles.append(helper)
	return pending_audio_profiles
