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

enum NAME_VARIETIES {STAR, PLANET, GENERIC_FLAIR, ASTEROID_BELT, WORMHOLE, STATION, STATION_FLAIR, SPACE_ANOMALY, SPACE_ANOMALY_FLAIR} #for generating star systems
var NAME_DATA: Dictionary = {
	NAME_VARIETIES.STAR: [],
	NAME_VARIETIES.PLANET: [],
	NAME_VARIETIES.GENERIC_FLAIR: [],
	NAME_VARIETIES.ASTEROID_BELT: [],
	NAME_VARIETIES.WORMHOLE: [],
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
	NAME_VARIETIES.STATION: "res://Data/Name Data/station_names.txt",
	NAME_VARIETIES.STATION_FLAIR: "res://Data/Name Data/station_flairs.txt",
	NAME_VARIETIES.SPACE_ANOMALY: "res://Data/Name Data/space_anomaly_names.txt",
	NAME_VARIETIES.SPACE_ANOMALY_FLAIR: "res://Data/Name Data/space_anomaly_flairs.txt"
}

func get_random_name_from_variety(variety: NAME_VARIETIES):
	match variety:
		NAME_VARIETIES.STAR:
			return dual_name_selection(NAME_VARIETIES.STAR, NAME_VARIETIES.GENERIC_FLAIR)
		NAME_VARIETIES.PLANET:
			return dual_name_selection(NAME_VARIETIES.PLANET, NAME_VARIETIES.GENERIC_FLAIR)
		NAME_VARIETIES.STATION:
			return dual_name_selection(NAME_VARIETIES.STATION, NAME_VARIETIES.STATION_FLAIR)
		NAME_VARIETIES.SPACE_ANOMALY:
			return dual_name_selection(NAME_VARIETIES.SPACE_ANOMALY, NAME_VARIETIES.SPACE_ANOMALY_FLAIR)
		_:
			return get_data_or_file_candidates(variety).pick_random()

func get_lines_from_file(file_path: String):
	var lines: Array = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line()
		if not line.is_empty():
			lines.append(line)
	file.close()
	return lines

func get_data_or_file_candidates(variety: NAME_VARIETIES):
	var data: Array = NAME_DATA.get(variety)
	if data.is_empty():
		return get_lines_from_file(NAME_FILE_PATHS.get(variety))
	else:
		return data

func dual_name_selection(variety1: NAME_VARIETIES, variety2: NAME_VARIETIES):
	return "%s %s" % [get_data_or_file_candidates(variety1).pick_random(),
	get_data_or_file_candidates(variety2).pick_random()]




func get_weighted_station_classifications() -> Dictionary:
	var weighted: Dictionary = {}
	for classification in STATION_CLASSIFICATION_CURVES:
		var curve = STATION_CLASSIFICATION_CURVES.get(classification)
		var weight = curve.sample(player_weirdness_index)
		weighted[classification] = {"name": classification, "weight": weight}
	print_debug("STATION CLASSIFICATION WEIGHTINGS : ", weighted)
	return weighted

func get_weighted_entity_classifications() -> Dictionary: 
	var weighted: Dictionary = {}
	for classification in ENTITY_CLASSIFICATION_CURVES:
		var curve = ENTITY_CLASSIFICATION_CURVES.get(classification)
		var weight = curve.sample(player_weirdness_index)
		weighted[classification] = {"name": classification, "weight": weight}
	print_debug("ENTITY CLASSIFICATION WEIGHTINGS : ", weighted)
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
		#var resource : Resource = load("user://stellar_cartographer_data.res")
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

func loadSettings() -> void:
	pass

func saveSettings() -> void:
	pass
