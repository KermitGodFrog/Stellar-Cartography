extends Resource
class_name starSystemAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

@export var identifier: int
@export var display_name: String

@export var previous_system: starSystemAPI
@export var destination_systems: Array[starSystemAPI]

@export var bodies: Array[bodyAPI]
@export var identifier_count: int = 1

const time: int = 1000
@export_storage var post_gen_location_candidates: Array = []
# ^^^ can be used for multiple passes of additional things, each pass removes used indexes from the array  

@export var name_scheme: game_data.NAME_SCHEMES = game_data.NAME_SCHEMES.STANDARD
@export var special_system_classification: game_data.SPECIAL_SYSTEM_CLASSIFICATIONS = game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.NONE
@export var system_hazard_classification: game_data.SYSTEM_HAZARD_CLASSIFICATIONS = game_data.SYSTEM_HAZARD_CLASSIFICATIONS.NONE
@export var system_hazard_metadata: Dictionary = {}

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

enum BODY_TYPES {STAR, PLANET, ASTEROID_BELT, WORMHOLE, STATION, SPACE_ANOMALY, SPACE_ENTITY, RENDEZVOUS_POINT, CUSTOM}

const star_types = {
	"M": {"name": "M", "weight_eg": 0.7645629, "weight_lg": 0.0000003},
	"K": {"name": "K", "weight_eg": 0.1213592, "weight_lg": 0.0012136},
	"G": {"name": "G", "weight_eg": 0.0764563, "weight_lg": 0.7645629},
	"F": {"name": "F", "weight_eg": 0.0303398, "weight_lg": 0.1213592},
	"A": {"name": "A", "weight_eg": 0.0060679, "weight_lg": 0.0764563},
	"B": {"name": "B", "weight_eg": 0.0012136, "weight_lg": 0.0303398},
	"O": {"name": "O", "weight_eg": 0.0000003, "weight_lg": 0.0060679}
}

const star_data = { #MASS IS IN SOLAR MASSES, RADIUS IS IN SOLAR RADII
	"M": {"solar_radius_min": 0.1, "solar_radius_max": 0.7, "solar_mass_min": 0.08, "solar_mass_max": 0.45, "luminosity_min": 0.01, "luminosity_max": 0.08, "color": Color.RED},
	"K": {"solar_radius_min": 0.7, "solar_radius_max": 0.96, "solar_mass_min": 0.45, "solar_mass_max": 0.8, "luminosity_min": 0.08, "luminosity_max": 0.6, "color": Color.ORANGE},
	"G": {"solar_radius_min": 0.96, "solar_radius_max": 1.15, "solar_mass_min": 0.8, "solar_mass_max": 1.04, "luminosity_min": 0.6, "luminosity_max": 1.5, "color": Color.YELLOW},
	"F": {"solar_radius_min": 1.15, "solar_radius_max": 1.4, "solar_mass_min": 1.04, "solar_mass_max": 1.4, "luminosity_min": 1.5, "luminosity_max": 5, "color": Color.WHITE_SMOKE},
	"A": {"solar_radius_min": 1.4, "solar_radius_max": 1.8, "solar_mass_min": 1.4, "solar_mass_max": 2.1, "luminosity_min": 5, "luminosity_max": 25, "color": Color.LIGHT_BLUE},
	"B": {"solar_radius_min": 1.8, "solar_radius_max": 6.6, "solar_mass_min": 2.1, "solar_mass_max": 16,"luminosity_min": 25000, "luminosity_max": 30000, "color": Color.BLUE_VIOLET},
	"O": {"solar_radius_min": 6.6, "solar_radius_max": 10, "solar_mass_min": 16, "solar_mass_max": 25, "luminosity_min": 30000, "luminosity_max": 50000, "color": Color.BLUE}
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

const planet_descriptions = {
	"Chthonian": "A solid planet which is, in itself, a metallic core. Result of a massive gravitational pull stripping the atmosphere of a Neptunian or Jovian world, leaving only the core behind.",
	"Lava": "A solid planet composed of silicate, carbon and trace rare elements, with extensive sulfur concentrated near the surface due to constant active volcanism. Metallic core.",
#	"Hycean": ,
	"Desert": "A solid planet with a human suitable nitrogen-oxygen atmosphere.",
	"Ocean": "A solid planet with a human suitable nitrogen-oxygen atmosphere.",
	"Earth-like": "A solid planet with a human suitable nitrogen-oxygen atmosphere.",
	"Ice": "A solid planet composed of silicate, water and carbon, with huge reservoirs of water, methane, ammonia and nitrogen at the surface. Metallic core.",
	"Iron": "A solid planet composed of silicate, water, carbon and trace rare elements accompanied by an iron core.",
	"Nickel": "A solid planet composed of silicate, water, carbon and trace rare elements accompanied by a nickel or iron-nickel core.",
	"Sulfur": "A solid planet composed of silicate, water, carbon and trace rare elements accompanied by a sulfur or iron-sulfur core.",
	"Coreless": "A solid planet composed of silicate, water, carbon and trace rare elements which is notably devoid of a core. Comparatively greater water content than Iron, Nickel and Sulfur planets.",
	"Carbon": "A solid planet composed of carbon in quantity, with trace amounts of silicate and rare elements, while being entirely devoid of water. Metallic core."
#	"Fire Dwarf": ,
#	"Gas Dwarf": ,
#	"Ice Dwarf": ,
#	"Helium Dwarf": ,
#	"Fire Giant": ,
#	"Gas Giant": ,
#	"Ice Giant": ,
#	"Helium Giant": ,
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

func createBase(_PA_chance_per_planet: float = 0.0, _missing_AO_chance_per_planet: float = 0.0, _SA_chance_per_candidate: float = 0.0) -> void:
	#generate just planets, stars and space anomalies!
	var hook_star = generateRandomWeightedHookStar()
	generateRandomWeightedPlanets(hook_star, _PA_chance_per_planet, _missing_AO_chance_per_planet)
	generateRandomAnomalies(_SA_chance_per_candidate)
	pass

func createAuxiliaryCivilized() -> void:
	generateWormholes()
	generateRandomWeightedStations()
	generateRandomWeightedEntities()
	generateRendezvousPoint()
	for body in bodies:
		body.known = true
	pass

func createAuxiliaryUnexplored() -> void:
	print_debug("CREATE AUXILIARY UNEXPLORED!!")
	var new_special_system_classification = global_data.weighted_pick(game_data.get_weighted_special_system_classifications(), "weight")
	special_system_classification = new_special_system_classification
	
	var new_system_hazard_classification = global_data.weighted_pick(game_data.get_weighted_system_hazard_classifications(), "weight")
	system_hazard_classification = new_system_hazard_classification
	
	match new_special_system_classification:
		game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.NONE:
			generateWormholes()
			generateRandomWeightedEntities()
			generateRendezvousPoint()
			generateRandomWeightedSpecialAnomaly()
		game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.VOID:
			#!! THIS DOES NOT WORK !! THIS DOES NOT WORK !! THIS DOES NOT WORK !! THIS DOES NOT WORK !!
			var star = get_first_star()
			var star_identifier = star.get_identifier()
			var remove_bodies: Array[bodyAPI] = []
			for body in get_bodies_with_hook_identifier(star_identifier):
				remove_bodies.append(body)
			for body in remove_bodies:
				bodies.erase(body)
			post_gen_location_candidates.clear()
			for i in star.metadata.get("iterations", 0):
				post_gen_location_candidates.append([star_identifier, i])
			generateWormholes() #i think this backtracking code is reasonable as something like this is one-of-a-kind and i probably wont be manually clearing bodies again
		#for example, a completely empty star system could use this match statement to REMOVE all existing bodies (besides the star) and spawn nothing else. Then an event could happen on concept enteringSystem 
	pass



func generateRandomWeightedHookStar():
	randomize()
	
	var star_type = global_data.weighted_pick(get_star_types_mixed_weights(), "weight")
	var data = star_data.get(star_type)
	
	var radius: float = global_data.get_randf(data.get("solar_radius_min"), data.get("solar_radius_max"))
	var mass: float = global_data.get_randf(data.get("solar_mass_min"), data.get("solar_mass_max"))
	var luminosity: float = global_data.get_randf(data.get("luminosity_min"), data.get("luminosity_max")) 
	
	var color = data.get("color")
	
	var multiplier = get_discovery_multiplier_from_star_type(star_type)
	
	var new_body = addBody(
		circularBodyAPI.new(),
		BODY_TYPES.STAR,
		identifier_count,
		game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.STAR, name_scheme),
		0, #identifier count starts at 1 so this shouldnt be any issue
		0.0,
		0.0,
		radius,
		{"mass": mass, "surface_color": color},
		{"star_type": star_type, "luminosity": luminosity, "discovery_multiplier": multiplier, "iterations": 25}
	)
	
	get_body_from_identifier(new_body).known = true #so you can see stars on system map before exploring
	return new_body

func generateRandomWeightedPlanets(hook_identifier: int, PA_chance_per_planet: float = 0.0, missing_AO_chance_per_planet: float = 0.0):
	randomize()
	var hook = get_body_from_identifier(hook_identifier)
	var remaining: Array = []
	
	if hook.metadata: if hook.metadata.has("iterations"):
		if not hook.get_type() == BODY_TYPES.STAR: if randf() >= 0.4: return
		
		for i in range(hook.metadata.get("iterations")):
			#SETTING DISTANCE
			var orbit_distance = get_orbit_distance(hook, i) #sets a base of the bodies radius + roche limit, increments upwards by 1.5x the bodies radius so subbodies cant touch each other
			var inner_boundry: float #has to be on this level so it can be used later
			var outer_boundry: float #has to be on this level so it can be used later
			if hook.get_type() == BODY_TYPES.STAR:
				inner_boundry = (sqrt((hook.metadata.get("luminosity") * 0.53))) * 215 #habitable inner boundry in solar radii (CONVERTED FROM AUs) no it isnt lol
				outer_boundry = (sqrt((hook.metadata.get("luminosity") * 1.1))) * 215 #habitable outer boundry in solar radii (CONVERTED FROM AUs) no it isnt lol
				#new_distance = ((inner_boundry + outer_boundry) / 2) * i
			
			#CHANCE TO SPAWN AN ASTEROID BELT INSTEAD
			if randf() <= 0.1:
				var belt_width = global_data.get_randf(hook.radius * 71, hook.radius * 645) #in solar radii. for reference, asteroid belt in the sol system is 215 solar radii
				#this works STUPID well /\/\/\/\/\
				if orbit_distance > belt_width:
					var belt_classification = global_data.weighted_pick(asteroid_belt_classifications, "weight")
					var belt_mass = global_data.get_randf(pow(10, -1.3) / 333000, pow(10, 0.22) / 333000)
					
					var new_belt = addBody(
						bodyAPI.new(),
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
					continue
			
			#PICKING PLANET CLASSIFICATION + DECIDING WHETHER TO SPAWN MOONS
			var generate_sub_bodies: bool = randf() > 0.75 #choose whether to give the new planet (hypothetically) moons, coaloquially known as 'sub bodies'
			if randf() >= 0.75: #choose whehter to have a planet at all
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
				var orbit_speed = get_random_orbit_speed(hook, orbit_distance)
				
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
				var new_planet = addBody(
					planetBodyAPI.new(),
					BODY_TYPES.PLANET,
					identifier_count,
					game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.PLANET, name_scheme, hook.get_display_name(), i, remaining.size()),
					hook.get_identifier(),
					orbit_distance,
					orbit_speed,
					(radius / 109.1),
					{"mass": (mass / 333000), "surface_color": color, "current_variation": planetBodyAPI.VARIATIONS.values().pick_random()},
					{"planet_classification": planet_classification, "planet_type": planet_type, "value": value, "iterations": (hook.metadata.get("iterations") / 2), "has_planetary_anomaly": has_planetary_anomaly, "is_planetary_anomaly_available": is_planetary_anomaly_available, "planetary_anomaly_seed": randi(), "has_missing_AO": has_missing_AO}
				)
				
				get_body_from_identifier(new_planet).rotation = deg_to_rad(global_data.get_randf(0,360))
				if generate_sub_bodies:
					generateRandomWeightedPlanets(new_planet, PA_chance_per_planet, missing_AO_chance_per_planet)
			else: remaining.append([hook_identifier, i]) #else condition all the way from the choice to even have a planet. !! does not check if asteroid belt was spawned instead !!
		
		#APPENDING POTENTIAL WORMHOLE LOCATION CANDIDATES TO GLOBAL VARIABLE
		if remaining:
			post_gen_location_candidates.append_array(remaining)
	pass

func generateWormholes(): #uses variables post_gen_location_candidates, destination_systems
	randomize()
	var spawn_systems = destination_systems.duplicate()
	if previous_system:
		spawn_systems.push_front(previous_system)
	for dest_system in spawn_systems:
		var location = post_gen_location_candidates.pick_random()
		var hook = get_body_from_identifier(location.front())
		var i = location.back()
		
		var orbit_distance = get_orbit_distance(hook, i)
		var orbit_speed = get_random_orbit_speed(hook, orbit_distance)
		
		#any size between the smallest terrestrial world, to half the size of the largest terrestrial world!
		var radius = global_data.get_randf(pow(pow(10, -1.3), 0.28), pow(pow(10, 0.22), 0.28) * 0.5)
		
		var new_wormhole = addBody(
			wormholeBodyAPI.new(),
			BODY_TYPES.WORMHOLE,
			identifier_count,
			game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.WORMHOLE, name_scheme, hook.get_display_name()),
			hook.get_identifier(),
			orbit_distance,
			orbit_speed,
			(radius / 109.1),
			{"destination_system": dest_system, "mass": 0.0, "surface_color": Color.WEB_PURPLE},
			{"destination_star_type": dest_system.get_first_star().metadata.get("star_type")}
		)
		
		get_body_from_identifier(new_wormhole).rotation = deg_to_rad(global_data.get_randf(0,360))
		if dest_system == previous_system:
			get_body_from_identifier(new_wormhole).disabled = true
		post_gen_location_candidates.remove_at(post_gen_location_candidates.find(location))
	pass

func generateRandomWeightedStations():
	randomize()
	for station in global_data.get_randi(1, 3):
		var location = post_gen_location_candidates.pick_random()
		var hook = get_body_from_identifier(location.front())
		var i = location.back()
		
		var orbit_distance = get_orbit_distance(hook, i)
		var orbit_speed = get_random_orbit_speed(hook, orbit_distance)
		var radius = get_default_radius_solar_radii()
		
		var station_classification = global_data.weighted_pick(game_data.get_weighted_station_classifications(), "weight")
		var percentage_markup = global_data.get_randi(75, 200)
		
		var new_station = addBody(
			stationBodyAPI.new(),
			BODY_TYPES.STATION,
			identifier_count,
			game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.STATION, name_scheme, hook.get_display_name()),
			hook.get_identifier(),
			orbit_distance,
			orbit_speed,
			radius,
			{"station_classification": station_classification, "sell_percentage_of_market_price": percentage_markup},
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
			var location = post_gen_location_candidates.pick_random()
			var hook = get_body_from_identifier(location.front())
			var i = location.back()
			
			var orbit_distance = get_orbit_distance(hook, i) 
			var orbit_speed = get_random_orbit_speed(hook, orbit_distance)
			var radius = get_default_radius_solar_radii()
			
			var new_anomaly = addBody(
				spaceAnomalyBodyAPI.new(),
				BODY_TYPES.SPACE_ANOMALY,
				identifier_count,
				game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.SPACE_ANOMALY, name_scheme, hook.get_display_name()),
				hook.get_identifier(),
				orbit_distance,
				orbit_speed,
				radius,
				{},
				{"space_anomaly_seed": randi()},
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
		var orbit_speed = get_random_orbit_speed(hook, orbit_distance)
		var radius = get_default_radius_solar_radii()
		
		var entity_classification = global_data.weighted_pick(game_data.get_weighted_entity_classifications(), "weight")
		
		var new_entity = addBody(
			entityBodyAPI.new(),
			BODY_TYPES.SPACE_ENTITY,
			identifier_count,
			game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.SPACE_ENTITY_DEFAULT, name_scheme, hook.get_display_name()),
			hook.get_identifier(),
			orbit_distance,
			orbit_speed,
			radius,
			{"entity_classification": entity_classification},
			{}
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
	var orbit_speed = get_random_orbit_speed(hook, orbit_distance)
	var radius = get_default_radius_solar_radii()
	
	var new_body = addBody(
		glintBodyAPI.new(),
		BODY_TYPES.RENDEZVOUS_POINT,
		identifier_count, 
		game_data.get_random_name_from_variety_for_scheme(game_data.NAME_VARIETIES.RENDEZVOUS_POINT_DEFAULT, name_scheme, hook.get_display_name()), 
		hook.get_identifier(),
		orbit_distance, 
		orbit_speed,
		radius,
		{}, #dialogue content overrides, perhaps?
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
	var orbit_speed = get_random_orbit_speed(hook, orbit_distance)
	var radius = get_default_radius_solar_radii()
	
	var special_anomaly_classification = global_data.weighted_pick(game_data.get_weighted_special_anomaly_classifications(), "weight")
	match special_anomaly_classification:
		game_data.SPECIAL_ANOMALY_CLASSIFICATIONS.SENTIENT_ASTEROID:
			var new_body = addBody(
				load("res://Data/BodyAPIs/Special/SpA_SentientAsteroid.gd").new(),
				BODY_TYPES.CUSTOM,
				identifier_count,
				"Unidentified Contact",
				hook.get_identifier(),
				orbit_distance,
				orbit_speed,
				radius,
				{"dialogue_tag": "SpA_SentientAsteroid", "_system_time": time, "_hook_mass": hook.mass, "_hook_radius": hook.radius, "min_distance": hook.radius * 71, "max_distance": hook.radius * 645, "icon_path": "res://Graphics/question_mark.png", "post_icon_path": "res://Graphics/SpA_SentientAsteroid_frame.png"},
				{}
			)
			get_body_from_identifier(new_body).rotation = deg_to_rad(global_data.get_randf(0,360))
			post_gen_location_candidates.remove_at(post_gen_location_candidates.find(location))
		game_data.SPECIAL_ANOMALY_CLASSIFICATIONS.NONE:
			pass
	pass



func get_random_orbit_speed(hook: bodyAPI, _orbit_distance: float) -> float:
	var orbit_speed_multiplier: float = 1.0
	if hook.orbit_speed > 0:
		orbit_speed_multiplier = ((hook.orbit_speed * 109.1) + 1)
	var minimum_speed: float = ((sqrt(47*(hook.mass) / hook.radius)) / time) / (_orbit_distance / 100) * orbit_speed_multiplier
	var maximum_speed: float = ((sqrt((2*47*hook.mass) / hook.radius)) / time) / (_orbit_distance / 100) * orbit_speed_multiplier
	#CHANCE FOR THE BODY TO ORBIT RETROGRADE:
	if randf() >= 0.975:
		minimum_speed = -minimum_speed
		maximum_speed = -maximum_speed
	
	return global_data.get_randf(minimum_speed, maximum_speed)

func get_orbit_distance(hook: bodyAPI, iteration: int) -> float:
	return hook.radius + pow(hook.radius, 1/3) + ((hook.radius * 10) * iteration)

func get_default_radius_solar_radii() -> float:
	return planet_classification_data.get("Terran").get("earth_radius_min") / 109.1

func get_star_types_mixed_weights() -> Dictionary:
	var mixed_types: Dictionary = {}
	for type in star_types:
		var sub_dict = star_types.get(type)
		var mixed_weight: float = lerpf(sub_dict.get("weight_eg"), sub_dict.get("weight_lg"), game_data.player_weirdness_index) #using game_data weirdness index seems to be the best call
		mixed_types[type] = {"name": type, "weight": mixed_weight}
	return mixed_types



func addBody(body: bodyAPI, _body_type: BODY_TYPES, id: int, d_name: String, hook_id: int, _orbit_distance: float, _orbit_speed: float, _radius: float, variables: Dictionary, metadata: Dictionary) -> int:
	body.set_type(_body_type)
	body.hook_identifier = hook_id
	body.set_identifier(id)
	identifier_count += 1
	body.set_display_name(d_name)
	body.orbit_distance = _orbit_distance
	body.orbit_speed = _orbit_speed
	body.radius = _radius
	for variable in variables:
		body.set(variable, variables.get(variable))
	body.set("metadata", metadata)
	body.initialize()
	bodies.append(body)
	return body.get_identifier()

func removeBody(id: int):
	for body in bodies:
		if body.get_identifier() == id:
			bodies.erase(body)
	pass

func updateBodyPosition(id: int, delta):
	var body = get_body_from_identifier(id)
	if body and body.hook_identifier != null:
		var hook = get_body_from_identifier(body.hook_identifier)
		if hook:
			body.position = hook.position
			if body.orbit_speed != 0 and body.orbit_distance != 0:
				var dir = Vector2.UP.rotated(body.rotation)
				body.rotation += body.orbit_speed * delta
				body.position = body.position + (dir * body.orbit_distance)
	pass




func get_random_body():
	return bodies.pick_random()

func get_random_planet(): #the fuck? why return an array????
	var planets: Array = []
	for body in bodies:
		if body.get_type() == BODY_TYPES.PLANET:
			planets.append(body)
	return planets

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

func get_discovery_multiplier_from_star_type(star_type: String) -> float:
	match star_type:
		"M": return 1.0
		"K": return 1.1
		"G": return 1.2
		"F": return 1.5
		"A": return 2.0
		"B": return 3.5
		"O": return 5.0
		_: return 1.0

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
		if body.hook_identifier == id:
			bodies_with_requested_hook_identifier.append(body)
	return bodies_with_requested_hook_identifier

func get_bodies_with_metadata_key(metadata_key: String) -> Array:
	var return_bodies: Array = []
	for body in bodies:
		if body.metadata.has(metadata_key):
			return_bodies.append(body)
	return return_bodies

func get_wormholes() -> Array:
	var wormholes: Array[wormholeBodyAPI] = []
	for body in bodies:
		if body.get_type() == BODY_TYPES.WORMHOLE:
			wormholes.append(body)
	return wormholes

func get_stations() -> Array:
	var stations: Array[stationBodyAPI] = []
	for body in bodies:
		if body.get_type() == BODY_TYPES.STATION:
			stations.append(body)
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

func is_civilized() -> bool:
	for body in bodies:
		if body.get_type() == BODY_TYPES.STATION:
			return true
	return false
