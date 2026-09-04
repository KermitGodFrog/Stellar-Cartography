extends Resource
class_name worldAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

@export_storage var play_time: float = 0.0 #probably the LEAST EFFICIENT WAY OF DOING THIS

@export var star_systems: Array[starSystemAPI]
@export var player: playerAPI
@export_storage var identifier_count: int = 1

@export var dialogue_memory: Dictionary = {} #how the fuck does it akways have access to the updated version of this???
@export var active_objectives: Array[objectiveAPI] = []

#KEY CUSTOMIZATION - ORIGINAL, UNCHANGED VALUES FROM GAME START
@export var _total_systems: int 
@export var _max_jumps: int
@export var _hull_stress_wormhole: int
@export var _hull_stress_CME: int
@export var _hull_stress_pulsar_beam: int
@export var _hull_stress_mine: int
@export var _scanner_profile: float
@export var _scanner_power: float

@export var SA_chance_per_candidate: float
@export var PA_chance_per_planet: float
@export var missing_AO_chance_per_planet: float
@export var missing_GL_chance_per_relevant_planet: float

#MISC!  >>>>>
@export var nav_buoy_tag: String = "" #for nav buoy space anomaly - i had no better place to put this!

@export_storage var played_frontier_leitmotif: bool = false #used exclusively in game.gd _on_player_entering_system()
@export_storage var played_abyss_leitmotif: bool = false #used exclusively in game.gd _on_player_entering_system()
# ^^^ neither of these are necessarily a player issue, thus are here instead
@export_storage var played_strange_discovery_theme: bool = false #used exclusively in game.gd _on_play_strange_discovery_theme_or_motif()
@export_storage var played_pulsar_theme: bool = false #used exclusively in game.gd _on_player_entering_system()



#mutations exclusion zone \/
enum MUTATION_ID {BASE, CONTENT_SKALIQ, OLD_NANITES, BETTER_ENGINES, BETTER_DATABANKS} #not related to the player but needs to be saved, thus worldAPI territory!
@export var installed_mutations: Array[MUTATION_ID] = []
##Returns false if the mutation was already installed.
func installMutation(mutation_idx: MUTATION_ID) -> bool:
	if not installed_mutations.has(mutation_idx):
		installed_mutations.append(mutation_idx)
		return true
	return false
##Returns false if the mutation was already uninstalled.
func uninstallMutation(mutation_idx: MUTATION_ID) -> bool: #you should never be uninstalling a mutation mid run but this exists regardless
	if installed_mutations.has(mutation_idx):
		installed_mutations.erase(mutation_idx)
		return true
	return false

const mutation_data: Dictionary = {
	MUTATION_ID.CONTENT_SKALIQ: {
		"title": "Content: The Skaliq",
		"headline": "A species of alien worms that are often encountered in deep space.",
		"description": "These sapient aliens, originating from the rings of a gas giant, are as devoted to exploration and pioneering as humans are. A skaliq colony is known to have coexisted with human residents of the Mashdari system since they arrived during the Late Proliferation. Once Mashdari was reconciled in 27AAT, those same residents shared Arata's theorem with their skaliq counterparts. Besides the few similarities, humans are very different to these aliens - beware of miscommunications.",
		"effect": "Adds 6 planetary anomalies, 6 space anomalies, 3 ship encounters, and other content.",
		"type": "NEUTRAL",
		"points_offset": 0
	},
	MUTATION_ID.OLD_NANITES: {
		"title": "Old Nanites",
		"headline": "An alternate universe where an outdated nanite design is universal.",
		"description": "In this alternate universe, the Provisional Executive never developed the Modern Era nanite in 14AAT. Reliance on the outdated 'universal nanite' carried by seeder ships during the latter half of the Late Proliferation Period continued instead.",
		"effect": "Repairing at space stations and settlements costs +50% more.",
		"type": "NEGATIVE",
		"points_offset": +1
	},
	MUTATION_ID.BETTER_ENGINES: {
		"title": "Better Engines",
		"headline": "",
		"description": "",
		"effect": "",
		"type": "POSITIVE",
		"points_offset": -1
	},
	MUTATION_ID.BETTER_DATABANKS: {
		"title": "Better Databanks",
		"headline": "",
		"description": "",
		"effect": "Discovering bodies yields 1.25x exploration data value.",
		"type": "POSITIVE",
		"points_offset": -1
	}
}
#mutations exclusion zone /\



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

func createPlayer(name: String, ship_name: String, prefix: String) -> playerAPI:
	var new_player = playerAPI.new()
	new_player.name = name
	new_player.ship_name = ship_name
	new_player.prefix = prefix
	new_player.speed = 5
	new_player.morale = 50
	new_player.radius = starSystemAPI.get_default_radius_solar_radii()
	new_player.metadata["affiliation"] = game_data.UNIT_AFFILIATIONS.PROVISIONAL_EXECUTIVE
	
	new_player.characters.append_array([
		load("uid://b0ufsv84pso1i").duplicate(true),
		load("uid://dshniitnvqmdm").duplicate(true),
		load("uid://bg402hymen2yw").duplicate(true),
		load("uid://btatr08y80g7t").duplicate(true)
	])
	
	new_player.max_jumps = _max_jumps
	new_player.total_systems = _total_systems
	new_player.hull_stress_wormhole = _hull_stress_wormhole
	new_player.hull_stress_CME = _hull_stress_CME
	new_player.hull_stress_pulsar_beam = _hull_stress_pulsar_beam
	new_player.hull_stress_mine = _hull_stress_mine
	new_player.scanner_profile = _scanner_profile
	new_player.scanner_power = _scanner_power
	
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

const advanced_analysis_multiplier: float = 1.1
func get_adjusted_SA_chance(advanced_analysis_unlocked: bool) -> float:
	if advanced_analysis_unlocked:
		return SA_chance_per_candidate * advanced_analysis_multiplier
	else:
		return SA_chance_per_candidate
func get_adjusted_PA_chance(advanced_analysis_unlocked: bool) -> float:
	if advanced_analysis_unlocked:
		return PA_chance_per_planet * advanced_analysis_multiplier
	else:
		return PA_chance_per_planet

func roll_nav_buoy(anomaly_seed: int) -> Array: #had no beter place to put this
	var new_tag = "%s-%03d" % [game_data.GRAPHEMES.keys().pick_random(), global_data.get_randi(0, 999)]
	var random = RandomNumberGenerator.new()
	random.set_seed(anomaly_seed)
	
	if nav_buoy_tag == "":
		nav_buoy_tag = new_tag
		return [nav_buoy_tag, true]
	else:
		if random.randf() >= 0.5:
			return [nav_buoy_tag, false]
		else:
			nav_buoy_tag = new_tag
			return [nav_buoy_tag, true]

func is_player_in_interception_danger() -> Array:
	var distances: PackedFloat32Array = []
	for c in player.scanner_contacts:
		if c.is_hostile():
			if c is interceptingUnitAPI:
				if c.current_task == c.TASKS.MOVE_TO_INTERCEPT:
					distances.append(c.position.distance_to(player.position))
			elif c is theatreMilitaryUnitAPI:
				if c.current_task == c.TASKS.MOVE_TO_INTERCEPT and c.goal == player:
					distances.append(c.position.distance_to(player.position))
	distances.sort()
	if distances.size() > 0:
		return [true, distances[0]]
	return [false, null]

func is_player_in_proximity_danger() -> bool:
	for c in player.current_star_system.get_units_in_scanner_range(player.position, player.scanner_power * 4.0): # within NOT ADJUSTED scanner power +400%
		if c.is_hostile():
			return true
	return false
