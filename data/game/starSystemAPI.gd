extends Resource
class_name starSystemAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

signal body_removed(id: int)
signal unit_following_body(b: bodyAPI, u: unitBodyAPI) #connected by game.gd _on_switch_star_system
signal unit_orbiting_body(b: bodyAPI, u: unitBodyAPI) #connected by game.gd _on_switch_star_system
signal unit_play_sound(path: String, volume_db: float, bus: StringName, u: unitBodyAPI) #connected by game.gd _on_switch_star_system
signal mine_detonated(id: int)

@export var identifier: int
@export var display_name: String
@export_storage var non_gen_seed: int = 0 #used by ESDs

@export var previous_system: starSystemAPI
@export var destination_systems: Array[starSystemAPI]

@export var bodies: Array[bodyAPI]
@export var identifier_count: int = 1

const time: int = 1
@export_storage var post_gen_location_candidates: Array = []
# ^^^ can be used for multiple passes of additional things, each pass removes used indexes from the array  

@export var name_scheme: game_data.NAME_SCHEMES = game_data.NAME_SCHEMES.STANDARD
@export var special_system_classification: game_data.SPECIAL_SYSTEM_CLASSIFICATIONS = game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.NONE
@export var system_hazard_classification: game_data.SYSTEM_HAZARD_CLASSIFICATIONS = game_data.SYSTEM_HAZARD_CLASSIFICATIONS.NONE
@export var system_hazard_metadata: Dictionary = {}
@export var system_scenario_classification: game_data.SYSTEM_SCENARIO_CLASSIFICATIONS = game_data.SYSTEM_SCENARIO_CLASSIFICATIONS.NONE

func get_identifier():
	return identifier
func set_identifier(new_identifier: int):
	identifier = new_identifier
	pass
func get_display_name():
	return display_name
func set_display_name(new_display_name: String):
	display_name = new_display_name
	pass

#universal element enums (grouped by equillibrium condensation temperature)
#enum SUPER_REFRACTORY {Re, Os, W, Zr, Hf}
#enum REFRACTORY {Al, Sc, Ca, Ti, Th, Lu, Tb, Dy, Ho, Er, Tm, Ir, Ru, Mo, U, Sm, Nd, La}
#enum MODERATELY_REFRACTORY {Nb, Be, V, Ce, Yb, Pt, Fe, Co, Ni, Pd, Mg, Eu, Si, Cr}
#enum MODERATELY_VOLATILE {Au, P, Li, Sr, Mn, Cu, Ba}
#enum VOLATILE {Rb, Cs, K, Ag, Na, B, Ga, Sn, Se, S}
#enum VERY_VOLATILE {Zn, Pb, In, Bi, Tl}

enum BODY_TYPES {STAR, PLANET, ASTEROID_BELT, WORMHOLE, STATION, SPACE_ANOMALY, SPACE_ENTITY, RENDEZVOUS_POINT, SCREEN_JUNK, CUSTOM, SHIP, MINE}

const star_types = {
	"M": {"name": "M", "weight_eg": 0.7645629, "weight_lg": 0.0000003},
	"K": {"name": "K", "weight_eg": 0.1213592, "weight_lg": 0.0012136},
	"G": {"name": "G", "weight_eg": 0.0764563, "weight_lg": 0.7645629},
	"F": {"name": "F", "weight_eg": 0.0303398, "weight_lg": 0.1213592},
	"A": {"name": "A", "weight_eg": 0.0060679, "weight_lg": 0.0764563},
	"B": {"name": "B", "weight_eg": 0.0012136, "weight_lg": 0.0303398},
	"O": {"name": "O", "weight_eg": 0.0000003, "weight_lg": 0.0060679},
	"Pulsar": {"name": "Pulsar", "weight_eg": 0.030, "weight_lg": 0.050}
}

const star_data = { #MASS IS IN SOLAR MASSES, RADIUS IS IN SOLAR RADII
	"M": {"solar_radius_min": 0.1, "solar_radius_max": 0.7, "solar_mass_min": 0.08, "solar_mass_max": 0.45, "luminosity_min": 0.01, "luminosity_max": 0.08, "color": Color.RED},
	"K": {"solar_radius_min": 0.7, "solar_radius_max": 0.96, "solar_mass_min": 0.45, "solar_mass_max": 0.8, "luminosity_min": 0.08, "luminosity_max": 0.6, "color": Color.ORANGE},
	"G": {"solar_radius_min": 0.96, "solar_radius_max": 1.15, "solar_mass_min": 0.8, "solar_mass_max": 1.04, "luminosity_min": 0.6, "luminosity_max": 1.5, "color": Color.YELLOW},
	"F": {"solar_radius_min": 1.15, "solar_radius_max": 1.4, "solar_mass_min": 1.04, "solar_mass_max": 1.4, "luminosity_min": 1.5, "luminosity_max": 5, "color": Color.WHITE_SMOKE},
	"A": {"solar_radius_min": 1.4, "solar_radius_max": 1.8, "solar_mass_min": 1.4, "solar_mass_max": 2.1, "luminosity_min": 5, "luminosity_max": 25, "color": Color.LIGHT_BLUE},
	"B": {"solar_radius_min": 1.8, "solar_radius_max": 6.6, "solar_mass_min": 2.1, "solar_mass_max": 16,"luminosity_min": 25000, "luminosity_max": 30000, "color": Color.BLUE_VIOLET},
	"O": {"solar_radius_min": 6.6, "solar_radius_max": 10, "solar_mass_min": 16, "solar_mass_max": 25, "luminosity_min": 30000, "luminosity_max": 50000, "color": Color.BLUE},
	"Pulsar": {"solar_radius_min": 0.1, "solar_radius_max": 1.15, "solar_mass_min": 1.44, "solar_mass_max": 2.9, "luminosity_min": 0.001, "luminosity_max": 0.01, "color": Color.WHITE}
}

const planet_classifications = {
	"Terran": {"name": "Terran", "weight": 0.3},
	"Neptunian": {"name": "Neptunian", "weight": 0.6},
	"Jovian": {"name": "Jovian", "weight": 0.15}
}

const planet_classification_data = { #MASS IS IN EARTH MASSES (DIVIDE BY 333000 FOR SOLAR MASSES), RADIUS IS IN EARTH RADIUS (DIVIDE BY 109.1 FOR SOLAR RADII)
	"Terran": {"earth_radius_min": pow(pow(10, -1.3), 0.28), "earth_radius_max": pow(pow(10, 0.22), 0.28),  "earth_mass_min": pow(10, -1.3), "earth_mass_max": pow(10, 0.22)}, 
	"Neptunian": {"earth_radius_min": pow(pow(10, 0.22), 0.59), "earth_radius_max": pow(pow(10, 2), 0.59), "earth_mass_min": pow(10, 0.22), "earth_mass_max": pow(10, 2)},
	"Jovian": {"earth_radius_min": pow(pow(10, 2), 0.4), "earth_radius_max": pow(pow(10, 3.5), 0.4), "earth_mass_min": pow(10, 2), "earth_mass_max": pow(10, 3.5)} #?????????????????????????
}

const planet_types = {
	"Terran": [{ # pre hab
		"Chthonian": {"name": "Chthonian", "weight": 0.1},
		"Lava": {"name": "Lava", "weight": 0.2}
	}, { # hab
		"Hycean": {"name": "Hycean", "weight": 0.2},
		"Desert": {"name": "Desert", "weight": 0.2},
		"Ocean": {"name": "Ocean", "weight": 0.2},
		"Earth-like": {"name": "Earth-like", "weight": 0.2}
	}, { # post hab
		"Ice": {"name": "Ice", "weight": 0.3}
	}, { # shared
		"Iron": {"name": "Silicate", "weight": 0.3},
		"Nickel": {"name": "Terrestrial", "weight": 0.3},
		"Sulfur": {"name": "Sulfur", "weight": 0.3},
		"Coreless": {"name": "Coreless", "weight": 0.3},
		"Carbon": {"name": "Carbon", "weight": 0.1},
	}],
	"Neptunian": [{ # pre hab
		"Fire Dwarf": {"name": "Fire Dwarf", "weight": 0.5}
	}, { # hab
		"Gas Dwarf": {"name": "Gas Dwarf", "weight": 0.5}
	}, { # post hab
		"Ice Dwarf": {"name": "Ice Dwarf", "weight": 0.5}
	}, { # shared
		"Helium Dwarf": {"name": "Helium Dwarf", "weight": 0.1}
	}],
	"Jovian": [{ # pre hab
		"Fire Giant": {"name": "Fire Giant", "weight": 0.5}
	}, { # hab
		"Gas Giant": {"name": "Gas Giant", "weight": 0.5}
	}, { # post hab
		"Ice Giant": {"name": "Ice Giant", "weight": 0.5}
	}, { # shared
		"Helium Giant": {"name": "Helium Giant", "weight": 0.1},
	}]
}

const planet_type_data = {
	"Chthonian": {"color": Color.DARK_RED, "avg_value": 4000, "variation_class": "density"},
	"Lava": {"color": Color.RED, "avg_value": 3000, "variation_class": "geological_activity"},
	"Hycean": {"color": Color.BLUE_VIOLET, "avg_value": 10000, "variation_class": "hydrogen_content"},
	"Desert": {"color": Color.DARK_KHAKI, "avg_value": 10000, "variation_class": "humidity"},
	"Ocean": {"color": Color.BLUE, "avg_value": 15000, "variation_class": "average_water_depth"},
	"Earth-like": {"color": Color.GREEN, "avg_value": 15000, "variation_class": "cloud_cover"},
	"Ice": {"color": Color.WHITE, "avg_value": 2500, "variation_class": "surface_reflectivity"},
	"Iron": {"color": Color.DARK_GRAY, "avg_value": 1000, "variation_class": "iron_core_size"},
	"Nickel": {"color": Color.LIGHT_SLATE_GRAY, "avg_value": 1000, "variation_class": "nickel_core_size"},
	"Sulfur": {"color": Color.WEB_GRAY, "avg_value": 1000, "variation_class": "sulfur_core_size"},
	"Coreless": {"color": Color.SLATE_GRAY, "avg_value": 1000, "variation_class": "terrain_amplitude"},
	"Carbon": {"color": Color.BLACK, "avg_value": 2500, "variation_class": "carbon_oxygen_difference"},
	"Fire Dwarf": {"color": Color.LIGHT_CORAL, "avg_value": 1000, "variation_class": "wind_speed"},
	"Gas Dwarf": {"color": Color.ORANGE, "avg_value": 2000, "variation_class": "water_content"},
	"Ice Dwarf": {"color": Color.DARK_BLUE, "avg_value": 3000, "variation_class": "volatile_content"},
	"Helium Dwarf": {"color": Color.DARK_ORANGE, "avg_value": 4500, "variation_class": "noble_gas_content"},
	"Fire Giant": {"color": Color.DARK_SALMON, "avg_value": 1000, "variation_class": "wind_speed"},
	"Gas Giant": {"color": Color.CORAL, "avg_value": 2000, "variation_class": "water_content"},
	"Ice Giant": {"color": Color.DARK_SLATE_BLUE, "avg_value": 3000, "variation_class": "volatile_content"},
	"Helium Giant": {"color": Color.ORANGE_RED, "avg_value": 4500, "variation_class": "noble_gas_content"} 
	#dwarfs and giants have the same audio data and thus can have the same variation class!
}


const planet_descriptions = { #currently accessed by: go-to interactions
	"Chthonian": "A solid planet which is, in itself, a metallic core. Result of a massive gravitational pull stripping the atmosphere of a Neptunian or Jovian world, leaving only the core behind.",
	"Lava": "A solid planet composed of silicate, carbon and trace rare elements, with extensive sulfur concentrated near the surface due to constant active volcanism. Metallic core.",
	"Hycean": "A solid planet with a hydrogen-rich atmosphere which is suitable for non-human forms of life, while having a largely ocean surface.",
	"Desert": "A solid planet with a human suitable nitrogen-oxygen atmosphere which has a dry surface that lacks any oceans.",
	"Ocean": "A solid planet with a human suitable nitrogen-oxygen atmosphere which has an entirely ocean surface.",
	"Earth-like": "A solid planet with a human suitable nitrogen-oxygen atmosphere which has a surface consisting of both continents and oceans.",
	"Ice": "A solid planet composed of silicate, water and carbon, with huge reservoirs of water, methane, ammonia and nitrogen at the surface. Metallic core.",
	"Iron": "A solid planet composed of silicate, water, carbon and trace rare elements accompanied by an iron core.",
	"Nickel": "A solid planet composed of silicate, water, carbon and trace rare elements accompanied by a nickel or iron-nickel core.",
	"Sulfur": "A solid planet composed of silicate, water, carbon and trace rare elements accompanied by a sulfur or iron-sulfur core.",
	"Coreless": "A solid planet composed of silicate, water, carbon and trace rare elements which is notably devoid of a core. Comparatively greater water content than Iron, Nickel and Sulfur planets.",
	"Carbon": "A solid planet composed of carbon in quantity, with trace amounts of silicate and rare elements, while being entirely devoid of water. Metallic core.",
	"Fire Dwarf": "A semi-gaseous planet with a high surface-atmosphere temperature and subsequent low atmospheric density.",
	"Gas Dwarf": "A semi-gaseous planet composed mainly of hydrogen and helium.",
	"Ice Dwarf": "A cold semi-gaseous planet composed of oxygen, carbon, nitrogen, sulfur and other heavier elements.",
	"Helium Dwarf": "A semi-gaseous planet composed of helium in quantity, with high levels of hydrogen monoxide and dioxide, while being entirely devoid of methane.",
	"Fire Giant": "A gaseous planet with a high surface-atmosphere temperature and subsequent low atmospheric density.",
	"Gas Giant": "A gaseous planet composed mainly of hydrogen and helium.",
	"Ice Giant": "A cold gaseous planet composed of oxygen, carbon, nitrogen, sulfur and other heavier elements.",
	"Helium Giant": "A gaseous planet composed of helium in quantity, with high levels of hydrogen monoxide and dioxide, while being entirely devoid of methane."
}

const star_descriptions = { #currently accessed by: go-to interactions
	"M": "NO DESCRIPTION YET",
	"K": "NO DESCRIPTION YET",
	"G": "NO DESCRIPTION YET",
	"F": "NO DESCRIPTION YET",
	"A": "NO DESCRIPTION YET",
	"B": "NO DESCRIPTION YET",
	"O": "NO DESCRIPTION YET",
	"Pulsar": "NO DESCRIPTION YET"
}


var LOW_VAR = planetBodyAPI.VARIATIONS.LOW #var LOW_VAR = bodyAPI.VARIATIONS.LOW
var MED_VAR = planetBodyAPI.VARIATIONS.MEDIUM #var MED_VAR = bodyAPI.VARIATIONS.MEDIUM
var HIGH_VAR = planetBodyAPI.VARIATIONS.HIGH #var HIGH_VAR = bodyAPI.VARIATIONS.HIGH
#CHIMES, POPS, PULSES, STORM, CUSTOM
var planet_type_audio_data = {
	"Chthonian": {LOW_VAR: [-80,-12,0,-80], MED_VAR: [-80,-6,-6,-80], HIGH_VAR: [-80,0,-12,-80]},
	"Lava": {LOW_VAR: [-80,-12,-12,-80], MED_VAR: [-80,-6,-12,-80], HIGH_VAR: [-80,0,-12,-80]},
	"Hycean": {LOW_VAR: [-12,-12,-80,-80], MED_VAR: [-6,-6,-80,-80], HIGH_VAR: [0,0,-80,-80]},
	"Desert": {LOW_VAR: [-80,-80,-80,-12], MED_VAR: [-80,-80,-80,-6], HIGH_VAR: [-80,-80,-80,0]},
	"Ocean": {LOW_VAR: [-12,-80,-80,-12], MED_VAR: [-6,-80,-80,-6], HIGH_VAR: [0,-80,-80,0]},
	"Earth-like": {LOW_VAR: [0,0,-12,-12], MED_VAR: [-6,0,-12,-6], HIGH_VAR: [-12,0,-12,0]},
	"Ice": {LOW_VAR: [-12,-80,-80,-80], MED_VAR: [-6,-80,-80,-80], HIGH_VAR: [0,-80,-80,-80]},
	"Iron": {LOW_VAR: [-12,0,-80,-80], MED_VAR: [-6,0,-80,-80], HIGH_VAR: [0,0,-70,-80]},
	"Nickel": {LOW_VAR: [-12,0,-70,-80], MED_VAR: [-6,0,-70,-80], HIGH_VAR: [0,0,-70,-80]},
	"Sulfur": {LOW_VAR: [-12,0,-12,-80], MED_VAR: [-6,0,-24,-80], HIGH_VAR: [0,0,-36,-80]},
	"Coreless": {LOW_VAR: [-80,-24,-80,-80], MED_VAR: [-80,-12,-80,-80], HIGH_VAR: [-80,0,-80,-80]},
	"Carbon": {LOW_VAR: [-12,-80,-6,-80], MED_VAR: [-6,-80,-3,-80], HIGH_VAR: [0,-80,0,-80]},
	"Fire Dwarf": {LOW_VAR: [-80,-12,-12,0], MED_VAR: [-80,-6,-6,0], HIGH_VAR: [-80,0,0,0]},
	"Gas Dwarf": {LOW_VAR: [-80,-80,-12,-12], MED_VAR: [-80,-80,-6,-12], HIGH_VAR: [-80,-80,0,-12]},
	"Ice Dwarf": {LOW_VAR: [-80,0,-80,-12], MED_VAR: [-80,-6,-80,-6], HIGH_VAR: [-80,-12,-80,0]},
	"Helium Dwarf": {LOW_VAR: [-12,-12,-80,-80], MED_VAR: [-6,-6,-80,-80], HIGH_VAR: [0,0,-80,-80]},
	"Fire Giant": {LOW_VAR: [-80,-12,-12,0], MED_VAR: [-80,-6,-6,0], HIGH_VAR: [-80,0,0,0]},
	"Gas Giant": {LOW_VAR: [-80,-80,-12,-12], MED_VAR: [-80,-80,-6,-12], HIGH_VAR: [-80,-80,0,-12]},
	"Ice Giant": {LOW_VAR: [-80,0,-80,-12], MED_VAR: [-80,-6,-80,-6], HIGH_VAR: [-80,-12,-80,0]},
	"Helium Giant": {LOW_VAR: [-12,-12,-80,-80], MED_VAR: [-6,-6,-80,-80], HIGH_VAR: [0,0,-80,-80]},
}

const asteroid_belt_classifications = {
	"Silicate": {"name": "Silicate", "weight": 0.3},
	"Metal-rich": {"name": "Metal-rich", "weight": 0.3},
	"Carbonaceous": {"name": "Carbonaceous", "weight": 0.3}
}

# core gen methods \/

func createBase(_PA_chance_per_planet: float = 0.0, _missing_AO_chance_per_planet: float = 0.0, _SA_chance_per_candidate: float = 0.0, _missing_GL_chance_per_relevant_planet: float = 0.0, weirdness_index: float = 0.0) -> void:
	if special_system_classification == game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.NONE:
		special_system_classification = global_data.weighted_pick(game_data.get_weighted_special_system_classifications(weirdness_index), "weight")
	
	if system_hazard_classification == game_data.SYSTEM_HAZARD_CLASSIFICATIONS.NONE:
		system_hazard_classification = global_data.weighted_pick(game_data.get_weighted_system_hazard_classifications(weirdness_index), "weight")
	
	if system_scenario_classification == game_data.SYSTEM_SCENARIO_CLASSIFICATIONS.NONE:
		system_scenario_classification = global_data.weighted_pick(game_data.get_weighted_system_scenario_classifications(weirdness_index), "weight")
	
	#generate just planets, stars and space anomalies!
	var hook_star = generateRandomWeightedHookStar()
	generateRandomWeightedPlanets(hook_star, _PA_chance_per_planet, _missing_AO_chance_per_planet, _missing_GL_chance_per_relevant_planet)
	generateRandomAnomalies(_SA_chance_per_candidate)
	generateFallbackAnomalies()
	generateRandomScreenJunk()
	pass

func createAuxiliaryCivilized(_unlocked_upgrades: Array[playerAPI.UPGRADE_ID] = []) -> void:
	match special_system_classification:
		game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.INSA:
			system_hazard_classification = game_data.SYSTEM_HAZARD_CLASSIFICATIONS.NONE
			system_scenario_classification = game_data.SYSTEM_SCENARIO_CLASSIFICATIONS.NONE
			print_debug("!! INSA SPECIAL SYSTEM CLASSIFICATION !!")
			const excluded_iterations := [0, 1, 5, 6, 10, 12, 18, 24]
			
			var insa_system = load("uid://bgyav54iwwu4").duplicate(true)
			
			removeAllBodies()
			post_gen_location_candidates.clear()
			bodies.append_array(insa_system.bodies)
			identifier_count = insa_system.identifier_count
			name_scheme = game_data.NAME_SCHEMES.STANDARD
			
			var insa_star = get_first_star()
			
			for b in bodies:
				if b.get_type() != BODY_TYPES.STAR and b.get_type() != BODY_TYPES.ASTEROID_BELT:
					b.radius = get_default_radius_solar_radii()
					b.rotation = deg_to_rad(global_data.get_randf(0,360))
			
			for i in insa_star.metadata.get("iterations"):
				print_debug("ITERATION %.f: %f | %f" % [i, get_orbit_distance(insa_star, i), get_orbit_angle_change(insa_star, get_orbit_distance(insa_star, i))])
			
			var wormholes: Array = get_wormholes()
			var systems = []
			systems.append(previous_system)
			systems.append_array(destination_systems)
			for wi in wormholes.size():
				var w = wormholes[wi]
				w.destination_system = systems[wi]
				w.metadata["destination_star_type"] = w.destination_system.get_first_star().metadata.get("star_type")
				w.destination_system.special_system_classification = game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.NONE
				w.destination_system.system_hazard_classification = game_data.SYSTEM_HAZARD_CLASSIFICATIONS.NONE
				w.destination_system.system_scenario_classification = game_data.SYSTEM_SCENARIO_CLASSIFICATIONS.NONE
			
			for belt in get_bodies_of_body_type(BODY_TYPES.ASTEROID_BELT):
				belt.metadata["belt_width"] = global_data.get_randf(20.0, 175.0)
			
			for i in insa_star.metadata.get("iterations", 0):
				if i in excluded_iterations:
					continue
				post_gen_location_candidates.append([insa_star.get_identifier(), i])
			
			var target_location = post_gen_location_candidates.pick_random()
			var target_hook = get_body_from_identifier(target_location.front())
			var target_i = target_location.back()
			var target_orbit_distance = get_orbit_distance(target_hook, target_i)
			var target_orbit_angle_change = get_orbit_angle_change(target_hook, target_orbit_distance)
			
			var target = addOrbitBody(
				planetBodyAPI.new(),
				BODY_TYPES.PLANET,
				identifier_count,
				"Kalama",
				1,
				target_orbit_distance,
				target_orbit_angle_change,
				pow(pow(10, 0.22), 0.28) / 109.1,
				{"mass": pow(10, 0.22) / 333000, "surface_color": planet_type_data.get("Lava").get("color"), "current_variation": 1},
				{"planet_classification": "Terran", "planet_type": "Lava", "value": 3005, "iterations": 12}
			)
			get_body_from_identifier(target).rotation = deg_to_rad(global_data.get_randf(0,360))
			post_gen_location_candidates.remove_at(post_gen_location_candidates.find(target_location))
			
			generateRendezvousPoint()
			
			for location in post_gen_location_candidates:
				if randf() >= 0.75:
					addRandomWeightedPlanetAtIteration(location.front(), location.back(), [])
					post_gen_location_candidates.remove_at(post_gen_location_candidates.find(location))
			
			var new_rally_point = addUnitBody(
				load("uid://jqe7kwgdyuxe").new(),
				starSystemAPI.BODY_TYPES.SHIP,
				identifier_count,
				"Rally Point",
				30,
				get_default_radius_solar_radii(),
				{"system": self, "hidden": true},
				{"affiliation": game_data.UNIT_AFFILIATIONS.INSA_CIVILIAN}
			)
			get_body_from_identifier(new_rally_point).position = Vector2.ZERO + (Vector2.UP.rotated(deg_to_rad(global_data.get_randf(0,360))) * 100.0)
			
			for i in 5:
				var new_ship = addUnitBody(
					theatreMilitaryUnitAPI.new(),
					starSystemAPI.BODY_TYPES.SHIP,
					identifier_count,
					game_data.get_random_starship_name(game_data.UNIT_AFFILIATIONS.INSA_MILITARY_A),
					4,
					get_default_radius_solar_radii(),
					{"system": self, "rally_point": get_body_from_identifier(new_rally_point), "hostile_affiliations": [game_data.UNIT_AFFILIATIONS.INSA_MILITARY_B, game_data.UNIT_AFFILIATIONS.PROVISIONAL_EXECUTIVE]},
					{"affiliation": game_data.UNIT_AFFILIATIONS.INSA_MILITARY_A, "hostile": true, "seed": randi()}
				)
				get_body_from_identifier(new_ship).position = Vector2.ZERO + (Vector2.UP.rotated(deg_to_rad(global_data.get_randf(0,360))) * global_data.get_randf(73.60, get_max_body_orbit_distance()))
			
			for i in 5:
				var new_ship = addUnitBody(
					theatreMilitaryUnitAPI.new(),
					starSystemAPI.BODY_TYPES.SHIP,
					identifier_count,
					game_data.get_random_starship_name(game_data.UNIT_AFFILIATIONS.INSA_MILITARY_B),
					4,
					get_default_radius_solar_radii(),
					{"system": self, "rally_point": get_body_from_identifier(new_rally_point), "hostile_affiliations": [game_data.UNIT_AFFILIATIONS.INSA_MILITARY_A, game_data.UNIT_AFFILIATIONS.PROVISIONAL_EXECUTIVE]},
					{"affiliation": game_data.UNIT_AFFILIATIONS.INSA_MILITARY_B, "hostile": true, "seed": randi()}
				)
				get_body_from_identifier(new_ship).position = Vector2.ZERO + (Vector2.UP.rotated(deg_to_rad(global_data.get_randf(0,360))) * global_data.get_randf(73.60, get_max_body_orbit_distance()))
			
			for i in 3:
				var new_ship = addUnitBody(
					wanderingUnitAPI.new(),
					starSystemAPI.BODY_TYPES.SHIP,
					identifier_count,
					game_data.get_random_starship_name(game_data.UNIT_AFFILIATIONS.INSA_CIVILIAN),
					3,
					get_default_radius_solar_radii(),
					{"system": self},
					{"affiliation": game_data.UNIT_AFFILIATIONS.INSA_CIVILIAN, "hostile": false, "seed": randi()}
				)
				get_body_from_identifier(new_ship).position = Vector2.ZERO + (Vector2.UP.rotated(deg_to_rad(global_data.get_randf(0,360))) * global_data.get_randf(73.60, get_max_body_orbit_distance()))
			
			#load a preset system from fs w/o the randgen planets and copy + paste the bodies and post_gen_location_candidates into here. then set the wormhole destination_systems and generate the planets. easy!
			#insa star info:
			#iteration: orbit distance | orbit angle change -->
			#iteration 0: 9.473905 | 0.834565 (wormhole #1)
			#iteration 1: 94.212955 | 0.035174 (rift driver)
			#iteration 5: 433.169155 | 0.003569 (insa ship wreck)
			#iteration 6: 517.908205 | 0.002730 (belt #1)
			#iteration 10: 856.864405 | 0.001283 (wormhole #2)
			#iteration 12: 1026.342505 | 0.000979 (belt #2)
			#iteration 18: 1534.776805 | 0.000535 (belt #3)
			#iteration 23: 1958.472055 | 0.000371
			#iteration 24: 2043.211105 | 0.000348 (wormhole #3)
		game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.NONE, _:
			system_hazard_classification = game_data.SYSTEM_HAZARD_CLASSIFICATIONS.NONE
			generateWormholes()
			generateRandomWeightedStations(_unlocked_upgrades)
			generateRandomWeightedEntities()
			generateRendezvousPoint()
			
			if randf() <= game_data.NETSPACE_TRANSMITTER_CHANCE_CURVE.sample(game_data.player_weirdness_index):
				var dict := get_quick_post_gen_dict()
				var new_body = addOrbitBody(
					customBodyAPI.new(),
					BODY_TYPES.CUSTOM,
					identifier_count,
					"Netspace Transmitter",
					dict.get("hook_identifier"),
					dict.get("orbit_distance"),
					dict.get("orbit_angle_change"),
					get_default_radius_solar_radii(),
					{"dialogue_tag": "netspaceTransmitter", "icon_path": "res://graphics/system-map/system-list/icons/netspaceTransmitter.png", "req_scope_mode": playerAPI.SCOPE_MODES.RAD}, #update "icon_path" with actual one!
					{}
				)
				get_body_from_identifier(new_body).rotation = deg_to_rad(global_data.get_randf(0,360))
				post_gen_location_candidates.remove_at(post_gen_location_candidates.find(dict.get("location")))
			
			for body in bodies:
				body.known = true
			generateRandomWeightedShips()
	pass

func createAuxiliaryUnexplored(_player_speed: int) -> void:
	match special_system_classification:
		game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.VOID:
			system_hazard_classification = game_data.SYSTEM_HAZARD_CLASSIFICATIONS.NONE
			system_scenario_classification = game_data.SYSTEM_SCENARIO_CLASSIFICATIONS.NONE
			var star = get_first_star()
			remove_recursive_bodies_with_hook_identifier(star.get_identifier())
			post_gen_location_candidates.clear()
			for i in star.metadata.get("iterations", 0):
				post_gen_location_candidates.append([star.get_identifier(), i])
			generateWormholes()
		game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.DYSON_SPHERE:
			system_hazard_classification = game_data.SYSTEM_HAZARD_CLASSIFICATIONS.NONE
			var star: circularBodyAPI = get_first_star()
			remove_recursive_bodies_with_hook_identifier(star.get_identifier())
			post_gen_location_candidates.clear()
			star.metadata["luminosity"] = star.metadata.get("luminosity") * 0.4 #assumption: the dyson sphere would reduce star light output by 60% !
			generateRandomWeightedPlanets(star.get_identifier())
			generateWormholes()
			generateRandomWeightedEntities()
			generateRendezvousPoint()
			generateRandomWeightedSpecialAnomaly()
			addOrbitBody(
				customBodyAPI.new(),
				starSystemAPI.BODY_TYPES.CUSTOM,
				identifier_count,
				"Dyson Sphere",
				star.get_identifier(),
				0.0,
				0.0,
				star.radius + 0.1,
				{"dialogue_tag": "SpA_DysonSphere", "icon_path": "res://graphics/system-map/system-list/icons/SpA_DysonSphere.png", "texture_path": "res://graphics/system-map/dyson_sphere_texture.png", "mesh_path": "res://meshes/system-3d/dyson_sphere.obj"},
				{}
			)
		game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.NONE, _:
			generateWormholes()
			generateRandomWeightedEntities()
			generateRendezvousPoint()
			generateRandomWeightedSpecialAnomaly()
			generateRandomWeightedShips()
	
	match system_hazard_classification:
		game_data.SYSTEM_HAZARD_CLASSIFICATIONS.MINE_FIELD:
			generateRandomMines(_player_speed)
		game_data.SYSTEM_HAZARD_CLASSIFICATIONS.NEBULA:
			const valid_nebula_colors := [
				Color.CHARTREUSE,
				Color.CORAL,
				Color.CRIMSON,
				Color.DARK_GREEN,
				Color.DEEP_SKY_BLUE,
				Color.DEEP_PINK,
				Color.MIDNIGHT_BLUE,
				Color.INDIGO
			]
			var noise: FastNoiseLite = FastNoiseLite.new()
			noise.set_seed(randi())
			noise.set_fractal_octaves(3)
			noise.set_fractal_weighted_strength(1.0)
			noise.set_noise_type(FastNoiseLite.TYPE_SIMPLEX)
			noise.set_fractal_type([FastNoiseLite.FRACTAL_NONE, FastNoiseLite.FRACTAL_PING_PONG, FastNoiseLite.FRACTAL_RIDGED].pick_random())
			noise.set_frequency(global_data.get_randf(0.001, 0.0075))
			system_hazard_metadata["nebula_noise"] = noise
			system_hazard_metadata["nebula_color"] = valid_nebula_colors.pick_random()
	pass

# gen methods \/

func generateRandomWeightedHookStar():
	randomize()
	
	var star_type = global_data.weighted_pick(get_star_types_mixed_weights(), "weight")
	var data = star_data.get(star_type)
	
	var radius: float = global_data.get_randf(data.get("solar_radius_min"), data.get("solar_radius_max"))
	var mass: float = global_data.get_randf(data.get("solar_mass_min"), data.get("solar_mass_max"))
	var luminosity: float = global_data.get_randf(data.get("luminosity_min"), data.get("luminosity_max")) 
	
	var color = data.get("color")
	
	var multiplier = get_discovery_multiplier_from_star_type(star_type)
	
	var new_body: int
	
	match star_type:
		"Pulsar":
			var beam_angle_change: float = global_data.get_randf(deg_to_rad(1), deg_to_rad(6))
			var beam_width: float = global_data.get_randf(10, 50) # IN SOLAR RADII
			
			new_body = addOrbitBody(
				pulsarBodyAPI.new(),
				BODY_TYPES.STAR,
				identifier_count,
				game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.STAR, name_scheme),
				0,
				0.0,
				0.0,
				radius,
				{"mass": mass, "surface_color": color, "beam_angle_change": beam_angle_change, "beam_width": beam_width},
				{"star_type": star_type, "luminosity": luminosity, "discovery_multiplier": multiplier, "iterations": 25, "seed": randi()}
			)
		_:
			new_body = addOrbitBody(
				circularBodyAPI.new(),
				BODY_TYPES.STAR,
				identifier_count,
				game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.STAR, name_scheme),
				0, #identifier count starts at 1 so this shouldnt be any issue
				0.0,
				0.0,
				radius,
				{"mass": mass, "surface_color": color},
				{"star_type": star_type, "luminosity": luminosity, "discovery_multiplier": multiplier, "iterations": 25, "seed": randi()}
			)
	
	get_body_from_identifier(new_body).known = true #so you can see stars on system map before exploring
	return new_body

func generateRandomWeightedPlanets(hook_identifier: int, PA_chance_per_planet: float = 0.0, missing_AO_chance_per_planet: float = 0.0, missing_GL_chance_per_relevant_planet: float = 0.0):
	randomize()
	var hook = get_body_from_identifier(hook_identifier)
	var remaining: Array = []
	
	if hook.metadata: if hook.metadata.has("iterations"):
		if not hook.get_type() == BODY_TYPES.STAR: if randf() >= 0.4: return
		
		for i in range(hook.metadata.get("iterations")):
			if randf() < 0.1:
				addRandomWeightedAsteroidBeltAtIteration(hook_identifier, i)
			elif randf() >= 0.75:
				addRandomWeightedPlanetAtIteration(hook_identifier, i, remaining, PA_chance_per_planet, missing_AO_chance_per_planet, missing_GL_chance_per_relevant_planet)
			else: remaining.append([hook_identifier, i]) 
	
	if remaining.size() > 0:
		post_gen_location_candidates.append_array(remaining)
	pass
func addRandomWeightedPlanetAtIteration(hook_identifier: int, i: int, remaining: Array, PA_chance_per_planet: float = 0.0, missing_AO_chance_per_planet: float = 0.0, missing_GL_chance_per_relevant_planet: float = 0.0) -> void:
	var hook = get_body_from_identifier(hook_identifier)
	
	#SETTING DISTANCE
	var orbit_distance = get_orbit_distance(hook, i) #sets a base of the bodies radius + roche limit, increments upwards by 1.5x the bodies radius so subbodies cant touch each other
	var inner_boundry: float #has to be on this level so it can be used later
	var outer_boundry: float #has to be on this level so it can be used later
	if hook.get_type() == BODY_TYPES.STAR:
		inner_boundry = (sqrt((hook.metadata.get("luminosity") * 0.53))) * 215 #habitable inner boundry in solar radii (CONVERTED FROM AUs) no it isnt lol
		outer_boundry = (sqrt((hook.metadata.get("luminosity") * 1.1))) * 215 #habitable outer boundry in solar radii (CONVERTED FROM AUs) no it isnt lol
		#new_distance = ((inner_boundry + outer_boundry) / 2) * i
	
	#PICKING PLANET CLASSIFICATION + DECIDING WHETHER TO SPAWN MOONS
	var generate_sub_bodies: bool = randf() > 0.75 #choose whether to give the new planet (hypothetically) moons, coaloquially known as 'sub bodies'
	var planet_classification
	if not hook.get_type() == BODY_TYPES.STAR:
		var corrected_planet_classifications = planet_classifications.duplicate(true)
		match hook.metadata.get("planet_classification"):
			"Terran":
				corrected_planet_classifications.erase("Neptunian")
				corrected_planet_classifications.erase("Jovian")
			"Neptunian":
				corrected_planet_classifications.erase("Neptunian") #this is necessary because neptunian worlds are so damn common. all moons of a neptunian planet would be neptunian moons if not the case!
				corrected_planet_classifications.erase("Jovian")
		planet_classification = global_data.weighted_pick(corrected_planet_classifications, "weight")
	else:
		planet_classification = global_data.weighted_pick(planet_classifications, "weight")
	
	#PICKING PLANET TYPE
	var planet_type
	var categories = planet_types.get(planet_classification)
	var candidates: Dictionary
	if hook.get_type() == BODY_TYPES.STAR:
		if orbit_distance < inner_boundry:
			candidates = categories[0].duplicate()
			candidates.merge(categories[3])
		elif orbit_distance > inner_boundry and orbit_distance < outer_boundry:
			candidates = categories[1].duplicate()
			candidates.merge(categories[3])
		elif orbit_distance > outer_boundry: #unsure of the effect of elif statements here
			candidates = categories[2].duplicate()
			candidates.merge(categories[3])
	else: candidates = categories[3]
	planet_type = global_data.weighted_pick(candidates, "weight")
	
	#PICKING PLANET MASS
	var mass: float
	var data = planet_classification_data.get(planet_classification)
	#var normal_mass_calc = global_data.get_randf(data.get("earth_mass_min"), data.get("earth_mass_max"))
	#dont forget to use minf and other float functions. integers coudl ruin this thing
	mass = global_data.get_randf(data.get("earth_mass_min"), minf(data.get("earth_mass_max"), hook.mass * 333000 * 0.75))
	#print("------------")
	#print("MINIMUM MASS (EARTH MASSES): ", data.get("earth_mass_min"))
	#print("MAXIMUM MASS (EARTH MASSES): ", data.get("earth_mass_max"))
	#print("HOST MASS (EARTH MASSSES): ", hook.metadata.get("mass") * 333000)
	#print("MAXIMUM MASS CONSOLIDATED: ", minf(data.get("earth_mass_max"), hook.metadata.get("mass") * 333000 * 0.75))
	#print("------------")
	#if hook.is_planet(): #this assumes that a moon with a radius of 0.75x its host will no longer be orbiting it. this is because i dont understand the maths to find a ""GRAVITATIONAL NULL POINT""
		
		#if hook.metadata.get("planet_classification") == "Terran":
			#mass = global_data.get_randf(data.get("earth_mass_min"), hook.metadata.get("mass") * 0.75)
		#else: mass = normal_mass_calc
	#else: mass = normal_mass_calc
	
	#PICKING RADIUS
	#var radius: float = global_data.get_randf(data.get("earth_radius_min"), data.get("earth_radius_max"))
	var radius: float = global_data.get_randf(data.get("earth_radius_min"), minf(data.get("earth_radius_max"), hook.radius * 109.1 * 0.75))
	#print("------------")
	#print("MINIMUM RADIUS (EARTH RADII): ", data.get("earth_radius_min"))
	#print("MAXIMUM RADIUS (EARTH RADII): ", data.get("earth_radius_max"))
	#print("HOST RADIUS (EARTH RADII): ", hook.radius * 109.1)
	#print("MAXIMUM RADIUS CONSOLIDATED: ", minf(data.get("earth_radius_max"), hook.radius * 109.1 * 0.75))
	#print("------------")
	
	#PICKING SPEED
	var orbit_angle_change = get_orbit_angle_change(hook, orbit_distance)
	
	#PICKING COLOR
	var color = planet_type_data.get(planet_type).get("color")
	
	#PICKING VALUE
	var avg_value = planet_type_data.get(planet_type).get("avg_value")
	var value = round(global_data.get_randf(avg_value * 0.5, avg_value * 1.5))
	
	#SETTING WHETHER THE BODY HAS A PLANETARY ANOMALY
	var has_planetary_anomaly: bool = false
	var is_planetary_anomaly_available: bool = false
	if randf() >= (1 - PA_chance_per_planet):
		has_planetary_anomaly = true
		is_planetary_anomaly_available = true
	
	var has_missing_AO: bool = false
	if randf() >= (1 - missing_AO_chance_per_planet):
		has_missing_AO = true
	
	var has_missing_GL: bool = false
	var gas_layers_sum: int = -1
	if randf() >= (1 - missing_GL_chance_per_relevant_planet):
		match planet_classification:
			"Terran":
				pass
			"Neptunian":
				has_missing_GL = true
				gas_layers_sum = global_data.get_randi(3, 5)
			"Jovian":
				has_missing_GL = true
				gas_layers_sum = global_data.get_randi(4, 9)
	
	var new_planet_id := addOrbitBody(
		planetBodyAPI.new(),
		BODY_TYPES.PLANET,
		identifier_count,
		game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.PLANET, name_scheme, hook.get_display_name(), i, remaining.size()),
		hook_identifier,
		orbit_distance,
		orbit_angle_change,
		(radius / 109.1),
		{"mass": (mass / 333000), "surface_color": color, "current_variation": planetBodyAPI.VARIATIONS.values().pick_random(), "layers": gas_layers_sum},
		{"planet_classification": planet_classification, "planet_type": planet_type, "value": value, "iterations": int(hook.metadata.get("iterations") / 2), "planetary_anomaly": has_planetary_anomaly, "planetary_anomaly_available": is_planetary_anomaly_available, "seed": randi(), "missing_AO": has_missing_AO, "missing_GL": has_missing_GL}
	)
	var new_planet: planetBodyAPI = get_body_from_identifier(new_planet_id)
	new_planet.rotation = deg_to_rad(global_data.get_randf(0,360))
	
	# \/ tries to add moons and adds remaining locations to post_gen OR just adds everything to post gen
	if generate_sub_bodies:
		generateRandomWeightedPlanets(new_planet_id, PA_chance_per_planet, missing_AO_chance_per_planet, missing_GL_chance_per_relevant_planet)
	else:
		for iter in int(new_planet.metadata.get("iterations") / 4):
			post_gen_location_candidates.append([new_planet_id, iter])
	pass
func addRandomWeightedAsteroidBeltAtIteration(hook_identifier: int, i: int) -> int: # has a chance to fail if orbit_distance > belt_width
	var hook = get_body_from_identifier(hook_identifier)
	var orbit_distance = get_orbit_distance(hook, i)
	
	var belt_width = global_data.get_randf(hook.radius * 71, hook.radius * 645) #in solar radii. for reference, asteroid belt in the sol system is 215 solar radii
	#this works STUPID well /\/\/\/\/\
	if orbit_distance > belt_width:
		var belt_classification = global_data.weighted_pick(asteroid_belt_classifications, "weight")
		var belt_mass = global_data.get_randf(pow(10, -1.3) / 333000, pow(10, 0.22) / 333000)
		
		var new_belt = addOrbitBody(
			orbitBodyAPI.new(),
			BODY_TYPES.ASTEROID_BELT,
			identifier_count, 
			game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.ASTEROID_BELT, name_scheme, hook.get_display_name()),
			hook.get_identifier(),
			orbit_distance,
			0.0,
			0.0, #cant be interacted with so who cares
			{"hidden": true},
			{"asteroid_belt_classification": belt_classification, "belt_width": belt_width, "belt_color": Color(0.111765, 0.111765, 0.111765, 0.9), "belt_mass": belt_mass}
		)
		
		if hook.get_type() == BODY_TYPES.STAR:
			get_body_from_identifier(new_belt).known = true
		return new_belt
	return -1

func generateWormholes(): #uses variables post_gen_location_candidates, destination_systems
	randomize()
	var insa_prerequisite: bool = false
	var spawn_systems = destination_systems.duplicate()
	if previous_system:
		spawn_systems.push_front(previous_system)
	for dest_system in spawn_systems:
		
		if dest_system.special_system_classification == game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.INSA:
			insa_prerequisite = true
		
		var location = post_gen_location_candidates.pick_random()
		var hook = get_body_from_identifier(location.front())
		var i = location.back()
		
		var orbit_distance = get_orbit_distance(hook, i)
		var orbit_angle_change = get_orbit_angle_change(hook, orbit_distance)
		
		#any size between the smallest terrestrial world, to half the size of the largest terrestrial world!
		var radius = global_data.get_randf(pow(pow(10, -1.3), 0.28), pow(pow(10, 0.22), 0.28) * 0.5) # this is divided by 109.1 in the addOrbitBody call 
		
		var new_wormhole = addOrbitBody(
			wormholeBodyAPI.new(),
			BODY_TYPES.WORMHOLE,
			identifier_count,
			game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.WORMHOLE, name_scheme, hook.get_display_name()),
			hook.get_identifier(),
			orbit_distance,
			orbit_angle_change,
			(radius / 109.1),
			{"destination_system": dest_system, "mass": 0.0, "surface_color": Color.WEB_PURPLE},
			{"destination_star_type": dest_system.get_first_star().metadata.get("star_type")}
		)
		
		get_body_from_identifier(new_wormhole).rotation = deg_to_rad(global_data.get_randf(0,360))
		if dest_system == previous_system:
			get_body_from_identifier(new_wormhole).disabled = true
		post_gen_location_candidates.remove_at(post_gen_location_candidates.find(location))
	
	if insa_prerequisite:
		for w in get_wormholes():
			if not w.destination_system.special_system_classification == game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.INSA:
				w.disabled = true
	pass

func generateRandomWeightedStations(unlocked_upgrades: Array[playerAPI.UPGRADE_ID] = []):
	randomize()
	for station in global_data.get_randi(1, 3):
		var location = post_gen_location_candidates.pick_random()
		var hook = get_body_from_identifier(location.front())
		var i = location.back()
		
		var orbit_distance = get_orbit_distance(hook, i)
		var orbit_angle_change = get_orbit_angle_change(hook, orbit_distance)
		var radius = get_default_radius_solar_radii()
		
		var station_classification = global_data.weighted_pick(game_data.get_weighted_station_classifications(), "weight")
		var percentage_markup = clampi(roundi(randfn(100.0, 15.0)), 25, 200)
		
		var repair_price_multiplier: float = 1.0
		
		var num_upgrades: int = clampi(roundi(randfn(3, 1)), 1, 6)
		var available_upgrades: Array[playerAPI.UPGRADE_ID] = []
		#firstly, force up to 2 upgrades that are already required for other upgrades to be in the list (to promote specialization throughout a run):
		if num_upgrades >= 2:
			var upgrades_req_existing: Array[playerAPI.UPGRADE_ID] = []
			for u in unlocked_upgrades:
				for uu in playerAPI.get_upgrades_with_requirement(u):
					if not upgrades_req_existing.has(uu):
						upgrades_req_existing.append(uu)
			if upgrades_req_existing.size() > 0:
				var reduce: int = global_data.get_randi(0, mini(upgrades_req_existing.size(), 2))
				for iu in reduce:
					var chosen_upgrade: playerAPI.UPGRADE_ID = upgrades_req_existing.pick_random()
					available_upgrades.append(chosen_upgrade)
					upgrades_req_existing.erase(chosen_upgrade)
					num_upgrades -= 1
		#then populate the rest of the upgrades with general no-requirement ones!
		var no_req_upgrades: Array[playerAPI.UPGRADE_ID] = playerAPI.get_all_upgrades_with_no_requirements()
		for n in num_upgrades:
			var chosen_upgrade: playerAPI.UPGRADE_ID = no_req_upgrades.pick_random()
			if not available_upgrades.has(chosen_upgrade):
				available_upgrades.append(chosen_upgrade)
				no_req_upgrades.erase(chosen_upgrade)
		
		var new_station = addOrbitBody(
			stationBodyAPI.new(),
			BODY_TYPES.STATION,
			identifier_count,
			game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.STATION, name_scheme, hook.get_display_name()),
			hook.get_identifier(),
			orbit_distance,
			orbit_angle_change,
			radius,
			{"station_classification": station_classification, "sell_percentage_of_market_price": percentage_markup, "repair_price_multiplier": repair_price_multiplier, "available_upgrades": available_upgrades, "req_scope_mode": playerAPI.SCOPE_MODES.RAD},
			{}
		)
		
		get_body_from_identifier(new_station).rotation = deg_to_rad(global_data.get_randf(0,360))
		post_gen_location_candidates.remove_at(post_gen_location_candidates.find(location))
	pass

func generateRandomAnomalies(SA_chance_per_candidate: float = 0.0):
	randomize()
	#anomalies = space anomalies - dialogue, disappear afterwards.
	for anomaly in post_gen_location_candidates.size(): #for this reason, have to generate anomalies LAST
		if randf() > (1 - SA_chance_per_candidate):
			addRandomSpaceAnomaly()
	pass
func addRandomSpaceAnomaly() -> void: #used in both generateRandomAnomalies and generateFallbackAnomalies
	var location = post_gen_location_candidates.pick_random()
	var hook = get_body_from_identifier(location.front())
	var i = location.back()
	
	var orbit_distance = get_orbit_distance(hook, i) 
	var orbit_angle_change = get_orbit_angle_change(hook, orbit_distance)
	var radius = get_default_radius_solar_radii()
	
	var new_anomaly = addOrbitBody(
		spaceAnomalyBodyAPI.new(),
		BODY_TYPES.SPACE_ANOMALY,
		identifier_count,
		game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.SPACE_ANOMALY, name_scheme, hook.get_display_name()),
		hook.get_identifier(),
		orbit_distance,
		orbit_angle_change,
		radius,
		{"req_scope_mode": playerAPI.SCOPE_MODES.RAD},
		{"seed": randi()},
	)
	
	get_body_from_identifier(new_anomaly).rotation = deg_to_rad(global_data.get_randf(0,360))
	post_gen_location_candidates.remove_at(post_gen_location_candidates.find(location))
	pass

func generateRandomWeightedEntities():
	randomize()
	#entities = no dialogue, viewable via long range scopes module
	for entity in global_data.get_randi(0, 2):
		var location = post_gen_location_candidates.pick_random()
		var hook = get_body_from_identifier(location.front())
		var i = location.back()
		
		var orbit_distance = get_orbit_distance(hook, i)
		var orbit_angle_change = get_orbit_angle_change(hook, orbit_distance)
		var radius = get_default_radius_solar_radii()
		
		var entity_classification = global_data.weighted_pick(game_data.get_weighted_entity_classifications(), "weight")
		
		var new_entity = addOrbitBody(
			entityBodyAPI.new(),
			BODY_TYPES.SPACE_ENTITY,
			identifier_count,
			game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.SPACE_ENTITY_DEFAULT, name_scheme, hook.get_display_name()),
			hook.get_identifier(),
			orbit_distance,
			orbit_angle_change,
			radius,
			{"entity_classification": entity_classification, "req_scope_mode": playerAPI.SCOPE_MODES.RAD},
			{"seed": randi()}
		)
		
		get_body_from_identifier(new_entity).rotation = deg_to_rad(global_data.get_randf(0,360))
		post_gen_location_candidates.remove_at(post_gen_location_candidates.find(location))
	pass

func generateRendezvousPoint():
	randomize()
	var location = post_gen_location_candidates.pick_random()
	var hook = get_body_from_identifier(location.front())
	var i = location.back()
	
	var orbit_distance = get_orbit_distance(hook, i)
	var orbit_angle_change = get_orbit_angle_change(hook, orbit_distance)
	var radius = get_default_radius_solar_radii()
	
	var new_body = addOrbitBody(
		glintBodyAPI.new(),
		BODY_TYPES.RENDEZVOUS_POINT,
		identifier_count, 
		game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.RENDEZVOUS_POINT_DEFAULT, name_scheme, hook.get_display_name()), 
		hook.get_identifier(),
		orbit_distance, 
		orbit_angle_change,
		radius,
		{"req_scope_mode": playerAPI.SCOPE_MODES.RAD}, #dialogue content overrides, perhaps?
		{}
	)
	
	get_body_from_identifier(new_body).rotation = deg_to_rad(global_data.get_randf(0,360))
	post_gen_location_candidates.remove_at(post_gen_location_candidates.find(location))
	pass

func generateRandomWeightedSpecialAnomaly():
	var location = post_gen_location_candidates.pick_random()
	var hook = get_body_from_identifier(location.front())
	var i = location.back()
	
	var orbit_distance = get_orbit_distance(hook, i)
	var orbit_angle_change = get_orbit_angle_change(hook, orbit_distance)
	var radius = get_default_radius_solar_radii()
	
	var special_anomaly_classification = global_data.weighted_pick(game_data.get_weighted_special_anomaly_classifications(), "weight")
	match special_anomaly_classification:
		game_data.SPECIAL_ANOMALY_CLASSIFICATIONS.RIGGED_ASTEROID:
			var hook_orbit_velocity = tan(hook.orbit_angle_change) * hook.orbit_distance #would have to recalculate every frame if not calculating now, which would be unnecessary
			var new_body = addOrbitBody(
				load("uid://lxeqs6ypk0ju").new(),
				BODY_TYPES.CUSTOM,
				identifier_count,
				"Asteroid?",
				hook.get_identifier(),
				orbit_distance,
				orbit_angle_change,
				radius,
				{"dialogue_tag": "SpA_RiggedAsteroid", "_hook_mass": hook.mass, "_hook_orbit_velocity": hook_orbit_velocity, "_system_time": time, "min_distance": hook.radius * 71, "max_distance": hook.radius * 645, "icon_path": "res://graphics/system-map/system-list/icons/SpA_RiggedAsteroid.png", "req_scope_mode": playerAPI.SCOPE_MODES.RAD, "seed": randi()},
				{}
			)
			get_body_from_identifier(new_body).rotation = deg_to_rad(global_data.get_randf(0,360))
			post_gen_location_candidates.remove_at(post_gen_location_candidates.find(location))
		game_data.SPECIAL_ANOMALY_CLASSIFICATIONS.RIFT_DRIVER:
			var new_body = addOrbitBody(
				riftDriverBodyAPI.new(),
				BODY_TYPES.CUSTOM,
				identifier_count,
				"Unknown Installation",
				hook.get_identifier(),
				orbit_distance,
				orbit_angle_change,
				radius,
				{"dialogue_tag": "SpA_RiftDriver", "icon_path": "res://graphics/system-map/system-list/icons/rift_driver.png", "post_icon_path": "res://graphics/system-map/system-list/icons/rift_driver.png", "req_scope_mode": playerAPI.SCOPE_MODES.RAD, "seed": randi()},
				{}
			)
			get_body_from_identifier(new_body).rotation = deg_to_rad(global_data.get_randf(0,360))
			post_gen_location_candidates.remove_at(post_gen_location_candidates.find(location))
		game_data.SPECIAL_ANOMALY_CLASSIFICATIONS.NETSPACE_RETRIEVAL_POINT:
			var new_body = addOrbitBody(
				customBodyAPI.new(),
				BODY_TYPES.CUSTOM,
				identifier_count,
				"Netspace Retrieval Point",
				hook.get_identifier(),
				orbit_distance,
				orbit_angle_change,
				radius,
				{"dialogue_tag": "netspaceRetrievalPoint", "req_scope_mode": playerAPI.SCOPE_MODES.RAD, "seed": randi()},
				{}
			)
			get_body_from_identifier(new_body).rotation = deg_to_rad(global_data.get_randf(0,360))
			post_gen_location_candidates.remove_at(post_gen_location_candidates.find(location))
		game_data.SPECIAL_ANOMALY_CLASSIFICATIONS.NONE:
			pass
	pass

func generateFallbackAnomalies():
	var planets: Array = get_bodies_of_body_type(BODY_TYPES.PLANET)
	var space_anomalies: Array = get_bodies_of_body_type(BODY_TYPES.SPACE_ANOMALY)
	var PAs: bool = false
	var SAs: bool = false
	
	for planet in planets:
		if planet.is_PA_valid():
			PAs = true
	if space_anomalies.size() > 0:
		SAs = true
	
	if not PAs and not SAs: #no anomalies
		if randf() >= 0.5:
			if planets.size() > 0:
				var target = planets.pick_random()
				target.metadata["planetary_anomaly"] = true
				target.metadata["planetary_anomaly_available"] = true
		else:
			addRandomSpaceAnomaly()
	pass

func generateRandomWeightedShips() -> void:
	randomize()
	var _units_generated: int = 0
	var generate_ships: bool = randf() <= game_data.SHIP_TOTAL_CHANCE_CURVE.sample(game_data.player_weirdness_index)
	if generate_ships:
		var chance_curve: Curve
		if is_civilized():
			chance_curve = game_data.SHIP_CIVILIZED_CHANCE_CURVE
		else:
			chance_curve = game_data.SHIP_UNEXPLORED_CHANCE_CURVE
		
		var max_units: int = int(game_data.SHIP_QUANTITY_CURVE.sample(game_data.player_weirdness_index))
		for unit in max_units:
			var generate_unit: bool = randf() <= chance_curve.sample(game_data.player_weirdness_index)
			if generate_unit:
				var planets = get_bodies_of_body_type(BODY_TYPES.PLANET)
				if planets:
					addRandomWeightedShip(planets.pick_random())
					_units_generated += 1
		
	print_rich("[color=RED]UNITS GENERATED: %.f" % _units_generated)
	pass
func addRandomWeightedShip(orbiting_body: orbitBodyAPI) -> void:
	randomize()
	var distribution_y_value = game_data.SHIP_AI_DISTRIBUTION_CURVE.sample(game_data.player_weirdness_index)
	var wandering: bool = randf() <= distribution_y_value
	
	#horrific, but it least it works
	var affiliation: game_data.UNIT_AFFILIATIONS = game_data.UNIT_AFFILIATIONS.PROVISIONAL_EXECUTIVE
	var executive_affiliated: bool = randf() <= game_data.SHIP_WANDERING_AFFILIATION_CURVE.sample(game_data.player_weirdness_index)
	match wandering:
		true when executive_affiliated:
			affiliation = game_data.UNIT_AFFILIATIONS.PROVISIONAL_EXECUTIVE
		true:
			affiliation = game_data.UNIT_AFFILIATIONS.LOCAL_CIVILIZATION
		false:
			affiliation = game_data.UNIT_AFFILIATIONS.MARAUDER
	
	var AI: AIUnitAPI = null
	match wandering:
		true when is_civilized():
			AI = wanderingUnitAPI.new()
		true when affiliation == game_data.UNIT_AFFILIATIONS.PROVISIONAL_EXECUTIVE:
			AI = exploringUnitAPI.new()
		true when affiliation == game_data.UNIT_AFFILIATIONS.LOCAL_CIVILIZATION:
			AI = wanderingUnitAPI.new()
		false:
			AI = interceptingUnitAPI.new()
		_:
			AI = wanderingUnitAPI.new()
	
	var speed: int = 0
	if wandering:
		speed = global_data.get_randi(1, 3)
	else:
		speed = global_data.get_randi(3, int(game_data.SHIP_HOSTILE_MAX_SPEED_CURVE.sample(game_data.player_weirdness_index)))
	
	var new_unit = addUnitBody(
		AI,
		BODY_TYPES.SHIP,
		identifier_count,
		game_data.get_random_starship_name(affiliation),
		speed,
		get_default_radius_solar_radii(),
		{"system": self},
		{"affiliation": affiliation, "hostile": affiliation == game_data.UNIT_AFFILIATIONS.MARAUDER, "seed": randi()}
	)
	
	var unit: AIUnitAPI = get_body_from_identifier(new_unit)
	unit.set_action_type(unitBodyAPI.ACTION_TYPES.NONE, null)
	updateBodyPosition(orbiting_body.get_identifier(), 1.0) #dont have access to physics delta time so just using 1.0 lol
	unit.position = unit.get_orbit_position_for_body(orbiting_body)
	# ^ this is SOMEWHAT fixed by updating the body position BUT i think if its a moon orbiting a planet, then the planets position will still be in the star so the unit will appear orbiting the star. not a big deal; just something to note
	unit.orbit_body(orbiting_body)
	unit.updatePosition(1.0)
	pass

func generateRandomMines(player_speed: int = 5) -> void: #called by game.gd _on_process_system_hazard
	var preset_distances: Array = []
	var star_id = get_first_star().get_identifier()
	for body in bodies:
		if body is orbitBodyAPI:
			if body.hook_identifier == star_id:
				if body.orbit_distance >= 35.0:
					preset_distances.append(body.orbit_distance)
	
	var max_distance = get_max_body_orbit_distance()
	for i in global_data.get_randi(8, 16):
		var dir = Vector2.UP.rotated(deg_to_rad(global_data.get_randf(0,360)))
		var pos: Vector2 = Vector2.ZERO
		match randf() >= 0.5:
			true when preset_distances.size() > 0:
				var distance = preset_distances.pick_random()
				pos = Vector2.ZERO + (dir * distance)
				preset_distances.erase(distance)
			false, _:
				pos = Vector2.ZERO + (dir * global_data.get_randf(35.0, max_distance))
		
		var exclusion_zone_radius = global_data.get_randi(5, 30)
		var max_detonation_time = maxf(1.0, float(exclusion_zone_radius) / (player_speed * 2.0)) # player speed * (boost multiplier - 3) <- (this is so its possible to interact with the mine, and a bit more fair) [what does this mean lol]
		
		addUnitBody(
			mineUnitAPI.new(),
			BODY_TYPES.MINE,
			identifier_count,
			"Mine %03d" % global_data.get_randi(0, 999),
			0,
			get_default_radius_solar_radii(),
			{"position": pos, "max_detonation_time": max_detonation_time},
			{"affiliation": game_data.UNIT_AFFILIATIONS.LOCAL_CIVILIZATION, "hostile": true, "exclusion_zone_radius": exclusion_zone_radius} #charge up time 2 seconds: 3 (player speed) * 5 (boost multiplier) = 15 solar radii / s
		)
	pass

func generateRandomScreenJunk() -> void:
	var junk_paths = ["res://graphics/system-map/junk/junk1.png", "res://graphics/system-map/junk/junk2.png", "res://graphics/system-map/junk/junk3.png", "res://graphics/system-map/junk/junk4.png", "res://graphics/system-map/junk/junk5.png", "res://graphics/system-map/junk/junk6.png", "res://graphics/system-map/junk/junk7.png"]
	var max_distance = get_max_body_orbit_distance()
	for i in global_data.get_randi(0, 5):
		var dir: Vector2 = Vector2.UP.rotated(deg_to_rad(global_data.get_randf(0,360)))
		var pos: Vector2 = Vector2.ZERO + (dir * global_data.get_randf(0.0, max_distance))
		var scale = global_data.get_randi(25, max_distance)
		var modulate = Color.WHITE
		if randf() > 0.75:
			modulate = Color.WHITE.darkened(global_data.get_randf(0.0, 0.5))
		
		addBody(
			screenJunkBodyAPI.new(),
			BODY_TYPES.SCREEN_JUNK,
			identifier_count,
			"Screen Junk",
			{"position": pos, "texture_path": junk_paths.pick_random(), "texture_scale": scale, "texture_modulate": modulate, "hidden": true},
			{}
		)
	pass

# generation related getters \/

func get_orbit_angle_change(hook: bodyAPI, _orbit_distance: float) -> float: #(per unit of time) 
	#v = √(GM/r), where G is gravitational constant, M is hook mass (central body mass) and r is orbit radius
	var hook_orbit_velocity = tan(hook.orbit_angle_change) * hook.orbit_distance # real orbital velocity = orbital velocity + hook orbital velocity
	var orbit_velocity = hook_orbit_velocity + (sqrt(47*(hook.mass) / _orbit_distance)) / time #this is the actual velocity of a body 
	var orbit_angle_change = atan(orbit_velocity / _orbit_distance) #this is the rotation change in radians per unit of time for the body
	
	#CHANCE FOR THE BODY TO ORBIT RETROGRADE:
	if randf() >= 0.975:
		orbit_angle_change = -orbit_angle_change
	
	return orbit_angle_change

func get_orbit_distance(hook: bodyAPI, iteration: int) -> float:
	return hook.radius + pow(hook.radius, 1/3) + ((hook.radius * 10) * iteration)

static func get_default_radius_solar_radii() -> float:
	#return planet_classification_data.get("Terran").get("earth_radius_min") / 109.1
	return pow(pow(10, -1.3), 0.28) / 109.1

func get_star_types_mixed_weights() -> Dictionary:
	var mixed_types: Dictionary = {}
	for type in star_types:
		var sub_dict = star_types.get(type)
		var mixed_weight: float = lerpf(sub_dict.get("weight_eg"), sub_dict.get("weight_lg"), game_data.player_weirdness_index) #using game_data weirdness index seems to be the best call
		mixed_types[type] = {"name": type, "weight": mixed_weight}
	return mixed_types

# core body methods \/

func addBody(body: bodyAPI, body_type: BODY_TYPES, id: int, d_name: String, variables: Dictionary, metadata: Dictionary) -> int:
	body.set_type(body_type)
	body.set_identifier(id)
	identifier_count += 1
	body.set_display_name(d_name)
	for variable in variables:
		if not variable in body:
			push_error("ERROR: variable '%s' does not exist within %s (DISPLAY NAME: '%s', TYPE: '%s')" % [variable, body, d_name, BODY_TYPES.find_key(body_type)])
			continue
		elif typeof(variables.get(variable)) != typeof(body.get(variable)) and (typeof(body.get(variable)) != TYPE_NIL): #may my beautiful simple function rest in peace because this line of code killed it
			push_warning("WARNING: typeof variable '%s' [%.f] does not match the typeof the corresponding variable within %s [%.f] (DISPLAY NAME: '%s', TYPE: '%s')" % [variable, typeof(variables.get(variable)), body, typeof(body.get(variable)), d_name, BODY_TYPES.find_key(body_type)])
			continue
		body.set(variable, variables.get(variable))
	body.set("metadata", metadata)
	body.initialize()
	bodies.append(body)
	return body.get_identifier()

func addOrbitBody(_body: orbitBodyAPI, _body_type: BODY_TYPES, _id: int, _d_name: String, _hook_id: int, _orbit_distance: float, _orbit_angle_change: float, _radius: float, _variables: Dictionary, _metadata: Dictionary) -> int:
	_variables["hook_identifier"] = _hook_id
	_variables["orbit_distance"] = _orbit_distance
	_variables["orbit_angle_change"] = _orbit_angle_change
	_variables["radius"] = _radius
	var id = addBody(_body, _body_type, _id, _d_name, _variables, _metadata)
	return id

func addUnitBody(_body: unitBodyAPI, _body_type: BODY_TYPES, _id: int, _d_name: String, _speed: int, _radius: float, _variables: Dictionary, _metadata: Dictionary) -> int:
	_variables["speed"] = _speed
	_variables["radius"] = _radius
	_variables["rotation_hint"] = deg_to_rad(global_data.get_randi(0,360))
	var id = addBody(_body, _body_type, _id, _d_name, _variables, _metadata)
	return id

func removeBody(id: int):
	for body in bodies:
		if body.get_identifier() == id:
			bodies.erase(body)
			emit_signal("body_removed", id)
	pass

func removeAllBodies() -> void:
	for body in bodies:
		emit_signal("body_removed", body.get_identifier())
	bodies.clear()
	pass

func updateBodies(delta) -> void: #position, advance function
	for body in bodies:
		updateBodyPosition(body.get_identifier(), delta)
		body.advance(delta) #capacity to do more stuff, can be overriden by classes that inherit bodyAPI
	pass

func updateBodyPosition(id: int, delta):
	var body = get_body_from_identifier(id)
	match body:
		_ when body is unitBodyAPI:
			body.updateActionBodyState()
			body.updatePosition(delta)
		_ when body is orbitBodyAPI:
			if body and body.hook_identifier != null:
				var hook = get_body_from_identifier(body.hook_identifier)
				if hook:
					body.position = hook.position
					if body.orbit_angle_change != 0 and body.orbit_distance != 0:
						var dir = Vector2.UP.rotated(body.rotation)
						body.rotation += body.orbit_angle_change * delta
						body.position = body.position + (dir * body.orbit_distance)
	pass

# misc \/

func get_random_body():
	return bodies.pick_random()

func get_first_star():
	for body in bodies:
		if body.get_type() == BODY_TYPES.STAR:
			return body
	return null

func get_first_star_discovery_multiplier() -> float:
	for body in bodies:
		if body.get_type() == BODY_TYPES.STAR:
			return body.metadata.get("discovery_multiplier")
	return 1.0

static func get_discovery_multiplier_from_star_type(star_type: String) -> float:
	match star_type:
		"M": return 1.0
		"K": return 1.1
		"G": return 1.2
		"F": return 1.5
		"A": return 2.0
		"B": return 3.5
		"O": return 5.0
		"Pulsar": return 2.0
		_: return 1.0

static func get_CCS_success_chance_from_star_type(star_type: String) -> float:
	match star_type:
		"M": return 0.05
		"K": return 0.1
		"G": return 0.2
		"F": return 0.3
		"A": return 0.7
		"B": return 0.75
		"O": return 0.8
		"Pulsar": return 0.2
		_: return 0.0

func get_body_from_identifier(id: int):
	var get_body: bodyAPI
	for body in bodies:
		if body.get_identifier() == id:
			get_body = body
			break
	return get_body

func get_bodies_with_hook_identifier(id: int) -> Array:
	var bodies_with_requested_hook_identifier: Array = []
	for body in bodies:
		if body.get("hook_identifier") != null:
			if body.hook_identifier == id:
				bodies_with_requested_hook_identifier.append(body)
	return bodies_with_requested_hook_identifier

func get_recursive_bodies_with_hook_identifier(id: int) -> Array[bodyAPI]:
	var recursive_bodies_with_id: Array[bodyAPI] = []
	for body in bodies:
		if body.get("hook_identifier") != null:
			if body.hook_identifier == id:
				recursive_bodies_with_id.append(body)
				recursive_bodies_with_id.append_array(get_recursive_bodies_with_hook_identifier(body.get_identifier()))
	return recursive_bodies_with_id

func get_bodies_with_metadata_key(metadata_key: String) -> Array:
	var return_bodies: Array = []
	for body in bodies:
		if body.metadata.has(metadata_key):
			return_bodies.append(body)
	return return_bodies

func get_planets() -> Array:
	var planets: Array = get_bodies_of_body_type(BODY_TYPES.PLANET)
	return planets

func get_wormholes() -> Array:
	var wormholes: Array = get_bodies_of_body_type(BODY_TYPES.WORMHOLE)
	return wormholes

func get_stations() -> Array:
	var stations: Array = get_bodies_of_body_type(BODY_TYPES.STATION)
	return stations

func get_wormhole_with_destination_system(dest_system: starSystemAPI) -> wormholeBodyAPI:
	for body in bodies:
		if body.get_type() == BODY_TYPES.WORMHOLE:
			if body.destination_system == dest_system:
				return body
	return null

func get_bodies_of_body_type(_body_type: BODY_TYPES):
	var return_bodies: Array = []
	for body in bodies:
		if body.get_type() == _body_type:
			return_bodies.append(body)
	return return_bodies

func get_max_body_orbit_distance() -> float:
	var distances: Array = []
	for body in bodies:
		if body is orbitBodyAPI:
			distances.append(body.orbit_distance)
	distances.sort()
	return distances.back()

func is_civilized() -> bool:
	for body in bodies:
		if body.get_type() == BODY_TYPES.STATION:
			return true
	return false

static func get_temporary_station(hook: bodyAPI) -> stationBodyAPI: # for anomalies!
	var temp_station: stationBodyAPI = stationBodyAPI.new()
	temp_station.set_display_name(game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.STATION, game_data.NAME_SCHEMES.STANDARD))
	temp_station.station_classification = game_data.STATION_CLASSIFICATIONS.PIRATE
	temp_station.repair_price_multiplier = 1.0
	var random = RandomNumberGenerator.new()
	random.set_seed(hook.metadata.get("seed", randi()))
	temp_station.sell_percentage_of_market_price = clampi(roundi(random.randfn(50.0, 10.0)), 15, 100)
	var num_upgrades: int = clampi(roundi(random.randfn(2, 1)), 1, 6)
	var _available_upgrades: Array[playerAPI.UPGRADE_ID] = []
	var no_req_upgrades: Array[playerAPI.UPGRADE_ID] = playerAPI.get_all_upgrades_with_no_requirements()
	for n in num_upgrades:
		var internal_random = RandomNumberGenerator.new()
		internal_random.set_seed(hash(random.get_seed() - n))
		var chosen_upgrade: playerAPI.UPGRADE_ID = no_req_upgrades[internal_random.randi_range(0, no_req_upgrades.size() - 1)]
		if not _available_upgrades.has(chosen_upgrade):
			_available_upgrades.append(chosen_upgrade)
			no_req_upgrades.erase(chosen_upgrade)
	temp_station.available_upgrades = _available_upgrades
	return temp_station

func remove_recursive_bodies_with_hook_identifier(id: int) -> void:
	var remove_body_ids: PackedInt32Array = []
	for body in get_recursive_bodies_with_hook_identifier(id):
		remove_body_ids.append(body.get_identifier())
	for body_id in remove_body_ids:
		removeBody(body_id)
	pass

func get_first_body_from_display_name(name: String) -> bodyAPI:
	var get_body: bodyAPI = null
	for body in bodies:
		if body.get_display_name() == name:
			get_body = body
			break
	return get_body

func is_survey_complete() -> bool:
	for body in bodies:
		if body.is_hidden():
			continue
		elif body is unitBodyAPI:
			continue
		elif body is screenJunkBodyAPI:
			continue #not super necessary since screen junk is set to 'hidden' upon creation nowadays
		
		if not body.is_known():
			return false
	return true

func get_quick_post_gen_dict() -> Dictionary:
	var dict: Dictionary = {}
	
	var location = post_gen_location_candidates.pick_random()
	var hook = get_body_from_identifier(location.front())
	var i = location.back()
	var orbit_distance = get_orbit_distance(hook, i)
	var orbit_angle_change = get_orbit_angle_change(hook, orbit_distance)
	
	dict["location"] = location
	dict["hook"] = hook
	dict["hook_identifier"] = hook.get_identifier()
	dict["i"] = i
	dict["orbit_distance"] = orbit_distance
	dict["orbit_angle_change"] = orbit_angle_change
	
	return dict

# unit stuff \/

func updateMinesGetDetonations(detonator_position: Vector2, delta, detonator_invulnerable: bool = false) -> int: #returns number of detonating mines this frame
	var detonations_this_frame: int = 0
	var mines = get_bodies_of_body_type(BODY_TYPES.MINE)
	if mines:
		for mine: mineUnitAPI in mines:
			if detonator_position.distance_to(mine.position) < mine.metadata.get("exclusion_zone_radius"):
				if not detonator_invulnerable:
					mine.tick_detonation_time(true, delta)
			else:
				mine.tick_detonation_time(false, delta)
			if mine.can_detonate():
				if not detonator_invulnerable:
					detonations_this_frame += 1
					mine.detonate()
					emit_signal("mine_detonated", mine.get_identifier())
					removeBody(mine.get_identifier())
	return detonations_this_frame

func get_units() -> Array[unitBodyAPI]: #gets all bodies extending unitBodyAPI
	var return_units: Array[unitBodyAPI] = []
	for body in bodies:
		if body is unitBodyAPI:
			return_units.append(body)
	return return_units

func get_units_in_scanner_range(pos: Vector2, size: float) -> Array[unitBodyAPI]:
	var units_in_range: Array[unitBodyAPI] = []
	var units = get_units()
	
	for unit in units:
		if unit.position.distance_to(pos) < size:
			units_in_range.append(unit)
	
	return units_in_range

func _on_unit_following_body(_b: bodyAPI, _u: unitBodyAPI) -> void: #connected by game.gd _on_switch_star_system
	emit_signal("unit_following_body", _b, _u)
	pass

func _on_unit_orbiting_body(_b: bodyAPI, _u: unitBodyAPI) -> void: #connected by game.gd _on_switch_star_system
	emit_signal("unit_orbiting_body", _b, _u)
	pass

func _on_unit_play_sound(_path: String, _volume_db: float, _bus: StringName, _u: unitBodyAPI) -> void: #connected by game.gd _on_switch_star_system
	emit_signal("unit_play_sound", _path, _volume_db, _bus, _u)
	pass
