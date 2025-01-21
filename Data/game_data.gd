extends Node

enum PAUSE_MODES {NONE, PAUSE_MENU, STATS_MENU, STATION_UI, DIALOGUE, WORMHOLE_MINIGAME}

var player_weirdness_index: float = 0.0
const GENERATION_VECTORS = [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK] #for use in long range scopes and its props!

enum STATION_CLASSIFICATIONS {STANDARD, PIRATE, ABANDONED, COVERUP, DEBRIS, ABANDONED_OPERATIONAL, ABANDONED_BACKROOMS, PARTIALLY_SALVAGED, BIRD}
const STATION_CLASSIFICATION_CURVES = {
	STATION_CLASSIFICATIONS.STANDARD: preload("res://Data/Spawn Data/Stations/standard.tres"), 
	STATION_CLASSIFICATIONS.PIRATE: preload("res://Data/Spawn Data/Stations/pirate.tres"), 
	STATION_CLASSIFICATIONS.ABANDONED: preload("res://Data/Spawn Data/Stations/abandoned.tres"), 
	STATION_CLASSIFICATIONS.COVERUP: preload("res://Data/Spawn Data/Stations/coverup.tres"), 
	STATION_CLASSIFICATIONS.DEBRIS: preload("res://Data/Spawn Data/Stations/debris.tres"), 
	STATION_CLASSIFICATIONS.ABANDONED_OPERATIONAL: preload("res://Data/Spawn Data/Stations/abandoned_operational.tres"), 
	STATION_CLASSIFICATIONS.ABANDONED_BACKROOMS: preload("res://Data/Spawn Data/Stations/abandoned_backrooms.tres"), 
	STATION_CLASSIFICATIONS.PARTIALLY_SALVAGED: preload("res://Data/Spawn Data/Stations/partially_salvaged.tres"), 
	STATION_CLASSIFICATIONS.BIRD: preload("res://Data/Spawn Data/Stations/bird.tres")
}

enum ENTITY_CLASSIFICATIONS {SPACE_WHALE_POD, LAGRANGE_CLOUD} 
const ENTITY_CLASSIFICATION_CURVES = {
	ENTITY_CLASSIFICATIONS.SPACE_WHALE_POD: preload("res://Data/Spawn Data/Entities/space_whale_pod.tres"),
	ENTITY_CLASSIFICATIONS.LAGRANGE_CLOUD: preload("res://Data/Spawn Data/Entities/lagrange_cloud.tres")
}

const REPAIR_CURVE = preload("res://Data/Spawn Data/repair_curve.tres")
const NANITE_CONTROLLER_REPAIR_CURVE = preload("res://Data/Spawn Data/nanite_controller_repair_curve.tres")

enum NAME_SCHEMES {STANDARD, SCIENTIFIC, TREK}
enum NAME_VARIETIES {STAR, PLANET, GENERIC_FLAIR, ASTEROID_BELT, WORMHOLE, WORMHOLE_FLAIR, STATION, STATION_FLAIR, SPACE_ANOMALY, SPACE_ANOMALY_FLAIR, SPACE_ENTITY_DEFAULT} #SPACE_ENTITY_DEFAULT exists because SCIENTIFIC name scheme will give a space entity something like "SF-1058" while STANDARD name scheme will give a space entity "stellar_phenomena"
var NAME_DATA: Dictionary = {
	NAME_VARIETIES.STAR: [],
	NAME_VARIETIES.PLANET: [],
	NAME_VARIETIES.GENERIC_FLAIR: [],
	NAME_VARIETIES.ASTEROID_BELT: [],
	NAME_VARIETIES.WORMHOLE: [],
	NAME_VARIETIES.WORMHOLE_FLAIR: [],
	NAME_VARIETIES.STATION: [],
	NAME_VARIETIES.STATION_FLAIR: [],
	NAME_VARIETIES.SPACE_ANOMALY: [],
	NAME_VARIETIES.SPACE_ANOMALY_FLAIR: []
}

const NAME_FILE_PATHS: Dictionary = {
	NAME_VARIETIES.STAR: "res://Data/Name Data/star_names.txt",
	NAME_VARIETIES.PLANET: "res://Data/Name Data/planet_names.txt",
	NAME_VARIETIES.GENERIC_FLAIR: "res://Data/Name Data/generic_flairs.txt",
	NAME_VARIETIES.ASTEROID_BELT: "res://Data/Name Data/asteroid_belt_names.txt",
	NAME_VARIETIES.WORMHOLE: "res://Data/Name Data/wormhole_names.txt",
	NAME_VARIETIES.WORMHOLE_FLAIR: "res://Data/Name Data/wormhole_flairs.txt",
	NAME_VARIETIES.STATION: "res://Data/Name Data/station_names.txt",
	NAME_VARIETIES.STATION_FLAIR: "res://Data/Name Data/station_flairs.txt",
	NAME_VARIETIES.SPACE_ANOMALY: "res://Data/Name Data/space_anomaly_names.txt",
	NAME_VARIETIES.SPACE_ANOMALY_FLAIR: "res://Data/Name Data/space_anomaly_flairs.txt"
}

const SETTINGS_RELEVANT_AUDIO_BUSES = ["Master", "Planetary SFX", "SFX", "Music"]
var DEFAULT_SETTINGS_RELEVANT_ACTION_EVENTS: Array[InputEvent] = []

func get_random_name_from_variety_for_scheme(variety: NAME_VARIETIES, scheme: NAME_SCHEMES, _hook_display_name: String = "", _iteration: int = -1, _remaining_size = -1):
	match scheme:
		NAME_SCHEMES.STANDARD:
			return STANDARD_get_random_name_from_variety(variety)
		NAME_SCHEMES.SCIENTIFIC:
			if SYSTEM_PREFIX.is_empty(): 
				SYSTEM_PREFIX = SCIENTIFIC_construct_system_prefix(maxi(1, round(randfn(3, 1))))
			return SCIENTIFIC_get_random_name_from_variety(variety, _hook_display_name, _iteration)
		NAME_SCHEMES.TREK:
			return TREK_get_random_name_from_variety(variety, _hook_display_name, _iteration, _remaining_size)
	pass


func TREK_get_random_name_from_variety(variety: NAME_VARIETIES, hook_display_name: String, iteration: int = -1, remaining_size: int = -1):
	match variety:
		NAME_VARIETIES.SPACE_ENTITY_DEFAULT:
			return "stellar_phenomena"
		NAME_VARIETIES.PLANET:
			if randf() >= 0.75:
				return STANDARD_dual_name_selection(NAME_VARIETIES.PLANET, NAME_VARIETIES.GENERIC_FLAIR)
			else:
				return "%s %s" % [hook_display_name, global_data.convertToRomanNumeral((iteration - remaining_size) + 1)]
		_:
			return STANDARD_get_random_name_from_variety(variety)


enum GRAPHEMES {
	B, BB, D, DD, ED, 
	F, FF, PH, GH, LF, 
	FT, G, GG, GU, GUE, 
	H, WH, J, GE, DGE, 
	DI, K, C, CH, CC, 
	LK, QU, Q, CK, X, 
	L, LL, M, MM, MB, 
	LM, N, NN, KN, GN, 
	PN, MN, P, PP, R, 
	RR, WR, RH, S, SS, 
	SC, PS, ST, CE, SE, 
	T, TT, TH, V, VE, 
	W, U, O, Z, ZZ, 
	ZE, SI, TCH, TU, TE, 
	SH, CI, SCI, TI, Y, 
	I, A #A is not part of this but i wanted the system to be able to auto generate the word 'IRAN' which is surprisingly common in this kinda thing
}
var SYSTEM_PREFIX: String = "" #this is reset whenever _on_create_star_system in game.gd is called. (kinda hacky)

func SCIENTIFIC_get_random_name_from_variety(variety: NAME_VARIETIES, hook_display_name: String, iteration: int = -1):
	match variety:
		NAME_VARIETIES.SPACE_ENTITY_DEFAULT:
			return "stellar_phenomena"
		NAME_VARIETIES.STAR:
			return "%s" % SYSTEM_PREFIX
		NAME_VARIETIES.PLANET:
			if hook_display_name.right(1).is_valid_int():
				return "%s %s" % [hook_display_name, global_data.convertToAlphabet(iteration + 1)]
			return "%s %03d" % [hook_display_name, iteration]
		NAME_VARIETIES.WORMHOLE:
			return "%s W-%03d" % [hook_display_name, global_data.get_randi(0, 999)]
		_:
			return STANDARD_get_random_name_from_variety(variety)

func SCIENTIFIC_construct_system_prefix(grapheme_count: int) -> String:
	randomize()
	var parts: PackedStringArray = []
	for i in grapheme_count:
		parts.append(GRAPHEMES.keys().pick_random())
	if randf() >= 0.25:
		return "-".join(parts)
	else:
		return "".join(parts)


func STANDARD_get_random_name_from_variety(variety: NAME_VARIETIES):
	match variety:
		NAME_VARIETIES.SPACE_ENTITY_DEFAULT:
			return "stellar_phenomena"
		NAME_VARIETIES.STAR:
			return STANDARD_dual_name_selection(NAME_VARIETIES.STAR, NAME_VARIETIES.GENERIC_FLAIR)
		NAME_VARIETIES.PLANET:
			return STANDARD_dual_name_selection(NAME_VARIETIES.PLANET, NAME_VARIETIES.GENERIC_FLAIR)
		NAME_VARIETIES.STATION:
			return STANDARD_dual_name_selection(NAME_VARIETIES.STATION, NAME_VARIETIES.STATION_FLAIR)
		NAME_VARIETIES.SPACE_ANOMALY:
			return STANDARD_dual_name_selection(NAME_VARIETIES.SPACE_ANOMALY, NAME_VARIETIES.SPACE_ANOMALY_FLAIR)
		NAME_VARIETIES.WORMHOLE:
			return STANDARD_dual_name_selection(NAME_VARIETIES.WORMHOLE, NAME_VARIETIES.WORMHOLE_FLAIR)
		_:
			return STANDARD_get_data_or_file_candidates(variety).pick_random()

func STANDARD_dual_name_selection(variety1: NAME_VARIETIES, variety2: NAME_VARIETIES):
	return "%s %s" % [STANDARD_get_data_or_file_candidates(variety1).pick_random(),
	STANDARD_get_data_or_file_candidates(variety2).pick_random()]

func STANDARD_get_data_or_file_candidates(variety: NAME_VARIETIES):
	var data: Array = NAME_DATA.get(variety)
	if data.is_empty():
		return get_lines_from_file(NAME_FILE_PATHS.get(variety))
	else:
		return data


func get_lines_from_file(file_path: String):
	var lines: Array = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line()
		if not line.is_empty():
			lines.append(line)
	file.close()
	return lines



func get_weighted_station_classifications() -> Dictionary:
	var weighted: Dictionary = {}
	for classification in STATION_CLASSIFICATION_CURVES:
		var curve = STATION_CLASSIFICATION_CURVES.get(classification)
		var weight = curve.sample(player_weirdness_index)
		weighted[classification] = {"name": classification, "weight": weight}
	#print_debug("STATION CLASSIFICATION WEIGHTINGS : ", weighted)
	return weighted

func get_weighted_entity_classifications() -> Dictionary: 
	var weighted: Dictionary = {}
	for classification in ENTITY_CLASSIFICATION_CURVES:
		var curve = ENTITY_CLASSIFICATION_CURVES.get(classification)
		var weight = curve.sample(player_weirdness_index)
		weighted[classification] = {"name": classification, "weight": weight}
	#print_debug("ENTITY CLASSIFICATION WEIGHTINGS : ", weighted)
	return weighted

func get_closest_body(bodies, pos):
	if bodies.size() > 0:
		var distance_to_bodies: Dictionary = {}
		for body in bodies:
			distance_to_bodies[body] = pos.distance_to(body.position)
		
		var corrected = distance_to_bodies.values()
		corrected.sort()
		return distance_to_bodies.find_key(corrected[0])
	else:
		return null



func loadWorld():
	print("GAME DATA: LOADING WORLD")
	if ResourceLoader.exists("user://stellar_cartographer_data.res"):
		var resource : Resource = ResourceLoader.load("user://stellar_cartographer_data.res", "", ResourceLoader.CACHE_MODE_IGNORE)
		return resource
	return null

func saveWorld(world: worldAPI) -> void:
	print("GAME DATA: SAVING WORLD")
	world.take_over_path("user://stellar_cartographer_data.res")
	var error = ResourceSaver.save(world, "user://stellar_cartographer_data.res", ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
	print("ERROR CODE: ", error)
	pass

func createWorld(_total_systems: int, _max_jumps: int, _hull_stress_highest_arc: int, _hull_stress_wormhole: int, _hull_stress_module: int, _SA_chance_per_candidate: float, _PA_chance_per_planet: float, _missing_AO_chance_per_planet: float) -> worldAPI:
	print("GAME DATA: CREATING WORLD")
	var world = worldAPI.new()
	world._max_jumps = _max_jumps
	world._total_systems = _total_systems
	world._hull_stress_highest_arc = _hull_stress_highest_arc
	world._hull_stress_wormhole = _hull_stress_wormhole
	world._hull_stress_module = _hull_stress_module
	world.SA_chance_per_candidate = _SA_chance_per_candidate
	world.PA_chance_per_planet = _PA_chance_per_planet
	world.missing_AO_chance_per_planet = _missing_AO_chance_per_planet
	return world

func deleteWorld() -> void:
	if ResourceLoader.exists("user://stellar_cartographer_data.res"):
		print("GAME DATA: DELETING WORLD")
		
		var error = DirAccess.remove_absolute("user://stellar_cartographer_data.res")
		print("ERROR CODE: ", error)
	pass



func loadSettings():
	print("GAME DATA: LOADING SETTINGS")
	if ResourceLoader.exists("user://stellar_cartographer_settings.res"):
		var resource : Resource = ResourceLoader.load("user://stellar_cartographer_settings.res")
		#print("LOADING SUCCESS") the resource being returned does not necessarily mean that the resource was loaded successfully!
		return resource
	#print("LOADING ERORR")
	print("FILE DOES NOT EXIST")
	return null

func saveSettings(settings_helper: settingsHelper) -> void:
	print("GAME DATA: SAVING SETTINGS")
	var error = ResourceSaver.save(settings_helper, "user://stellar_cartographer_settings.res")
	print("ERROR CODE: ", error)
	pass



func loadAchievements():
	print("GAME DATA: LOADING ACHIEVEMENTS")
	if ResourceLoader.exists("user://stellar_cartographer_achievements.res"):
		var resource : Resource = ResourceLoader.load("user://stellar_cartographer_achievements.res")
		#print("LOADING SUCCESS") the resource being returned does not necessarily mean that the resource was loaded successfully!
		return resource
	#print("LOADING ERROR")
	print("FILE DOES NOT EXIST")
	return null

func saveAchievements(achievements_helper: achievementsHelper) -> void:
	print("GAME DATA: SAVING ACHIEVEMENTS")
	var error = ResourceSaver.save(achievements_helper, "user://stellar_cartographer_achievements.res")
	print("ERROR CODE: ", error)
	pass
