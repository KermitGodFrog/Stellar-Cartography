extends Resource
class_name starSystemAPI

var identifier: int
var display_name: String

var previous_system: starSystemAPI
var destination_systems: Array[starSystemAPI]

var bodies: Array[bodyAPI]
var identifier_count: int = 1

var time: int = 1000
var post_gen_location_candidates: Array = []
# ^^^ can be used for multiple passes of additional things, each pass removes used indexes from the array  

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

var star_types = {
	"M": {"name": "M", "weight": 0.7645629},
	"K": {"name": "K", "weight": 0.1213592},
	"G": {"name": "G", "weight": 0.0764563},
	"F": {"name": "F", "weight": 0.0303398},
	"A": {"name": "A", "weight": 0.0060679},
	"B": {"name": "B", "weight": 0.0012136},
	"O": {"name": "O", "weight": 0.0000003}
}

var star_data = { #MASS IS IN SOLAR MASSES, RADIUS IS IN SOLAR RADII
	"M": {"solar_radius_min": 0.1, "solar_radius_max": 0.7, "solar_mass_min": 0.08, "solar_mass_max": 0.45, "luminosity_min": 0.01, "luminosity_max": 0.08, "color": Color.RED},
	"K": {"solar_radius_min": 0.7, "solar_radius_max": 0.96, "solar_mass_min": 0.45, "solar_mass_max": 0.8, "luminosity_min": 0.08, "luminosity_max": 0.6, "color": Color.ORANGE},
	"G": {"solar_radius_min": 0.96, "solar_radius_max": 1.15, "solar_mass_min": 0.8, "solar_mass_max": 1.04, "luminosity_min": 0.6, "luminosity_max": 1.5, "color": Color.YELLOW},
	"F": {"solar_radius_min": 1.15, "solar_radius_max": 1.4, "solar_mass_min": 1.04, "solar_mass_max": 1.4, "luminosity_min": 1.5, "luminosity_max": 5, "color": Color.WHITE_SMOKE},
	"A": {"solar_radius_min": 1.4, "solar_radius_max": 1.8, "solar_mass_min": 1.4, "solar_mass_max": 2.1, "luminosity_min": 5, "luminosity_max": 25, "color": Color.LIGHT_BLUE},
	"B": {"solar_radius_min": 1.8, "solar_radius_max": 6.6, "solar_mass_min": 2.1, "solar_mass_max": 16,"luminosity_min": 25000, "luminosity_max": 30000, "color": Color.BLUE_VIOLET},
	"O": {"solar_radius_min": 6.6, "solar_radius_max": 10, "solar_mass_min": 16, "solar_mass_max": 25, "luminosity_min": 30000, "luminosity_max": 50000, "color": Color.BLUE}
}

var planet_classifications = {
	"Terran": {"name": "Terran", "weight": 0.3},
	"Neptunian": {"name": "Neptunian", "weight": 0.6},
	"Jovian": {"name": "Jovian", "weight": 0.15}
}

var planet_classification_data = { #MASS IS IN EARTH MASSES (DIVIDE BY 333000 FOR SOLAR MASSES), RADIUS IS IN EARTH RADIUS (DIVIDE BY 109.1 FOR SOLAR RADIUS)
	"Terran": {"earth_radius_min": pow(pow(10, -1.3), 0.28), "earth_radius_max": pow(pow(10, 0.22), 0.28),  "earth_mass_min": pow(10, -1.3), "earth_mass_max": pow(10, 0.22)}, 
	"Neptunian": {"earth_radius_min": pow(pow(10, 0.22), 0.59), "earth_radius_max": pow(pow(10, 2), 0.59), "earth_mass_min": pow(10, 0.22), "earth_mass_max": pow(10, 2)},
	"Jovian": {"earth_radius_min": pow(pow(10, 2), 0.4), "earth_radius_max": pow(pow(10, 3.5), 0.4), "earth_mass_min": pow(10, 2), "earth_mass_max": pow(10, 3.5)} #?????????????????????????
}

var planet_types = {
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
		"Silicate": {"name": "Silicate", "weight": 0.7},
		"Terrestrial": {"name": "Terrestrial", "weight": 0.7},
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

var planet_type_data = {
	"Chthonian": {"color": Color.DARK_RED, "avg_value": 4000, "variation_class": "density"},
	"Lava": {"color": Color.RED, "avg_value": 3000, "variation_class": "geological_activity"},
	"Hycean": {"color": Color.BLUE_VIOLET, "avg_value": 10000, "variation_class": "hydrogen_content"},
	"Desert": {"color": Color.DARK_KHAKI, "avg_value": 10000, "variation_class": "humidity"},
	"Ocean": {"color": Color.BLUE, "avg_value": 15000, "variation_class": "average_water_depth"},
	"Earth-like": {"color": Color.GREEN, "avg_value": 15000, "variation_class": "cloud_cover"},
	"Ice": {"color": Color.WHITE, "avg_value": 2500, "variation_class": "surface_reflectivity"},
	"Silicate": {"color": Color.DARK_GRAY, "avg_value": 1000, "variation_class": "terrain_amplitude"},
	"Terrestrial": {"color": Color.DARK_SLATE_GRAY, "avg_value": 1000, "variation_class": "terrain_amplitude"},
	"Carbon": {"color": Color.BLACK, "avg_value": 2500, "variation_class": "carbon_oxygen_difference"},
	"Fire Dwarf": {"color": Color.LIGHT_CORAL, "avg_value": 1000, "variation_class": "wind_speed"},
	"Gas Dwarf": {"color": Color.ORANGE, "avg_value": 2000, "variation_class": "water_content"},
	"Ice Dwarf": {"color": Color.DARK_BLUE, "avg_value": 3000, "variation_class": "volatile_content"},
	"Helium Dwarf": {"color": Color.DARK_ORANGE, "avg_value": 4500, "variation_class": "noble_gas_content"},
	"Fire Giant": {"color": Color.DARK_SALMON, "avg_value": 1000, "variation_class": "wind_speed"},
	"Gas Giant": {"color": Color.CORAL, "avg_value": 2000, "variation_class": "water_content"},
	"Ice Giant": {"color": Color.DARK_SLATE_BLUE, "avg_value": 3000, "variation_class": "volatile_content"},
	"Helium Giant": {"color": Color.ORANGE_RED, "avg_value": 4500, "variation_class": "noble_gas_content"}
}

var LOW_VAR = bodyAPI.VARIATIONS.LOW
var MED_VAR = bodyAPI.VARIATIONS.MEDIUM
var HIGH_VAR = bodyAPI.VARIATIONS.HIGH
#CHIMES, POPS, PULSES, STORM, CUSTOM
var planet_type_audio_data = {
	"Chthonian": {LOW_VAR: [-80,-12,0,-80], MED_VAR: [-80,-6,-6,-80], HIGH_VAR: [-80,0,-12,-80]},
	"Lava": {LOW_VAR: [-80,-12,-12,-80], MED_VAR: [-80,-6,-12,-80], HIGH_VAR: [-80,0,-12,-80]},
	"Hycean": {LOW_VAR: [-12,-12,-80,-80], MED_VAR: [-6,-6,-80,-80], HIGH_VAR: [0,0,-80,-80]},
	"Desert": {LOW_VAR: [-80,-80,-80,-12], MED_VAR: [-80,-80,-80,-6], HIGH_VAR: [-80,-80,-80,0]},
	"Ocean": {LOW_VAR: [-12,-80,-80,-12], MED_VAR: [-6,-80,-80,-6], HIGH_VAR: [0,-80,-80,0]},
	"Earth-like": {LOW_VAR: [0,0,-12,-12], MED_VAR: [-6,0,-12,-6], HIGH_VAR: [-12,0,-12,0]},
	"Ice": {LOW_VAR: [-12,-80,-80,-80], MED_VAR: [-6,-80,-80,-80], HIGH_VAR: [0,-80,-80,-80]},
	"Silicate": {LOW_VAR: [-12,0,-80,-80], MED_VAR: [-6,0,-80,-80], HIGH_VAR: [0,0,-80,-80]},
	"Terrestrial": {LOW_VAR: [-12,0,-70,-80], MED_VAR: [-6,0,-70,-80], HIGH_VAR: [0,0,-70,-80]},
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

var asteroid_belt_classifications = {
	"Silicate": {"name": "Silicate", "weight": 0.3},
	"Metal-rich": {"name": "Metal-rich", "weight": 0.3},
	"Carbonaceous": {"name": "Carbonaceous", "weight": 0.3}
}

func createRandomWeightedPrimaryHookStar():
	randomize()
	var star_type = global_data.weighted_pick(star_types, "weight")
	var data = star_data.get(star_type)
	
	var mass: float = global_data.get_randf(data.get("solar_mass_min"), data.get("solar_mass_max"))
	var radius: float = global_data.get_randf(data.get("solar_radius_min"), data.get("solar_radius_max"))
	var luminosity: float = global_data.get_randf(data.get("luminosity_min"), data.get("luminosity_max")) 
	
	var color = data.get("color")
	
	var new_body = addStationaryBody(identifier_count, str(get_random_star_name()), null, radius, {"star_type": star_type, "mass": mass, "luminosity": luminosity, "color": color, "iterations": 25})
	get_body_from_identifier(new_body).is_known = true #so you can see stars on system map before exploring
	return new_body

func generateRandomWeightedBodies(hook_identifier: int):
	randomize()
	var hook = get_body_from_identifier(hook_identifier)
	var remaining: Array = []
	
	if hook.metadata: if hook.metadata.has("iterations"):
		if not hook.is_star(): if randf() >= 0.4: return
		
		for i in range(hook.metadata.get("iterations")):
			#SETTING DISTANCE
			var new_distance: float = hook.radius + pow(hook.radius, 1/3) + ((hook.radius * 10) * i) #sets a base of the bodies radius + roche limit, increments upwards by 1.5x the bodies radius so subbodies cant touch each other
			var inner_boundry: float #has to be on this level so it can be used later
			var outer_boundry: float #has to be on this level so it can be used later
			if hook.is_star():
				inner_boundry = (sqrt((hook.metadata.get("luminosity") * 0.53))) * 215 #habitable inner boundry in solar radii (CONVERTED FROM AUs) no it isnt lol
				outer_boundry = (sqrt((hook.metadata.get("luminosity") * 1.1))) * 215 #habitable outer boundry in solar radii (CONVERTED FROM AUs) no it isnt lol
				#new_distance = ((inner_boundry + outer_boundry) / 2) * i
			
			#CHANCE TO SPAWN AN ASTEROID BELT INSTEAD
			if randf() <= 0.1:
				var belt_width = global_data.get_randf(hook.radius * 71, hook.radius * 645) #in solar radii. for reference, asteroid belt in the sol system is 215 solar radii
				if new_distance > belt_width:
					var belt_classification = global_data.weighted_pick(asteroid_belt_classifications, "weight")
					var new_belt = addStationaryBody(identifier_count, str(get_random_asteroid_belt_name()), hook_identifier, new_distance, {"asteroid_belt_classification": belt_classification, "mass": (global_data.get_randf(pow(10, -1.3) / 333000, pow(10, 0.22) / 333000)), "width": belt_width, "color": Color(0.111765, 0.111765, 0.111765, 1), "iterations": (hook.metadata.get("iterations") / 2)})
					if hook.is_star():
						get_body_from_identifier(new_belt).is_known = true
					continue
			
			#PICKING PLANET CLASSIFICATION + DECIDING WHETHER TO SPAWN MOONS
			var generate_sub_bodies: bool = randf() > 0.75 #choose whether to give the new planet (hypothetically) moons, coaloquially known as 'sub bodies'
			if randf() >= 0.75: #choose whehter to have a planet at all
				var planet_classification
				if not hook.is_star():
					var corrected_planet_classifications = planet_classifications.duplicate(true)
					match hook.metadata.get("planet_classification"):
						"Terran":
							corrected_planet_classifications.erase("Neptunian")
							corrected_planet_classifications.erase("Jovian")
						"Neptunian":
							corrected_planet_classifications.erase("Neptunian") #maybe dont have?
							corrected_planet_classifications.erase("Jovian")
					planet_classification = global_data.weighted_pick(corrected_planet_classifications, "weight")
				else:
					planet_classification = global_data.weighted_pick(planet_classifications, "weight")
				
				#POICKING PLANET TYPE
				var planet_type
				var categories = planet_types.get(planet_classification)
				var candidates: Dictionary
				if hook.is_star():
					if new_distance < inner_boundry:
						candidates = categories[0].duplicate()
						candidates.merge(categories[3])
					if new_distance > inner_boundry and new_distance < outer_boundry:
						candidates = categories[1].duplicate()
						candidates.merge(categories[3])
					if new_distance > outer_boundry:
						candidates = categories[2].duplicate()
						candidates.merge(categories[3])
				else: candidates = categories[3]
				planet_type = global_data.weighted_pick(candidates, "weight")
				
				#PICKING PLANET MASS
				var mass: float
				var data = planet_classification_data.get(planet_classification)
				var normal_mass_calc = global_data.get_randf(data.get("earth_mass_min"), data.get("earth_mass_max"))
				
				if hook.is_planet():
					if hook.metadata.get("planet_classification") == "Terran":
						mass = global_data.get_randf(data.get("earth_mass_min"), hook.metadata.get("mass"))
					else: mass = normal_mass_calc
				else: mass = normal_mass_calc
				
				#PICKING RADIUS
				var radius: float = global_data.get_randf(data.get("earth_radius_min"), data.get("earth_radius_max"))
				
				#PICKING SPEED
				var orbit_speed_multiplier: float
				if hook.orbit_speed > 0: orbit_speed_multiplier = ((hook.orbit_speed * 109.1) + 1)
				else: orbit_speed_multiplier = 1
				
				var minimum_speed: float = ((sqrt(47*(hook.metadata.get("mass")) / hook.radius)) / time) / (new_distance / 100) * orbit_speed_multiplier
				var maximum_speed: float = ((sqrt((2*47*hook.metadata.get("mass")) / hook.radius)) / time) / (new_distance / 100) * orbit_speed_multiplier
				#CHANCE FOR THE BODY TO ORBIT RETROGRADE:
				if randf() >= 0.95:
					minimum_speed = -minimum_speed
					maximum_speed = -maximum_speed
				
				#PICKING COLOR
				var color = planet_type_data.get(planet_type).get("color")
				
				#PICKING VALUE
				var avg_value = planet_type_data.get(planet_type).get("avg_value")
				var value = round(global_data.get_randf(avg_value * 0.5, avg_value * 1.5))
				
				#SPAWNING PLANET + PLANET MOONS
				var new_body = addBody(identifier_count, str(get_random_planet_name()), hook_identifier, new_distance, global_data.get_randf(minimum_speed, maximum_speed), (radius / 109.1), {"planet_classification": planet_classification, "planet_type": planet_type, "mass": (mass / 333000), "color": color, "value": value, "iterations": (hook.metadata.get("iterations") / 2)})
				get_body_from_identifier(new_body).rotation = deg_to_rad(global_data.get_randf(0,360))
				
				if generate_sub_bodies:
					generateRandomWeightedBodies(new_body)
			else: remaining.append([hook_identifier, i]) #else condition all the way from the choice to even have a planet. !! does not check if asteroid belt was spawned instead !!
		
		#APPENDING POTENTIAL WORMHOLE LOCATION CANDIDATES TO GLOBAL VARIABLE
		if remaining: post_gen_location_candidates.append_array(remaining)
	pass

func generateRandomWormholes(): #uses variables post_gen_location_candidates, destination_systems
	randomize()
	var spawn_systems = destination_systems.duplicate()
	if previous_system:
		spawn_systems.push_front(previous_system)
	for dest_system in spawn_systems:
		var location = post_gen_location_candidates.pick_random()
		var hook = get_body_from_identifier(location.front())
		var i = location.back()
		
		#whole bunch of stuff borrowed from generateRandomWeightedBodies
		var new_distance: float = hook.radius + pow(hook.radius, 1/3) + ((hook.radius * 10) * i)
		var orbit_speed_multiplier: float
		if hook.orbit_speed > 0: orbit_speed_multiplier = ((hook.orbit_speed * 109.1) + 1)
		else: orbit_speed_multiplier = 1
		
		var minimum_speed: float = ((sqrt(47*(hook.metadata.get("mass")) / hook.radius)) / time) / (new_distance / 100) * orbit_speed_multiplier
		var maximum_speed: float = ((sqrt((2*47*hook.metadata.get("mass")) / hook.radius)) / time) / (new_distance / 100) * orbit_speed_multiplier
		
		#any size between the smallest terrestrial world, to half the size of the largest terrestrial world!
		var radius = global_data.get_randf(pow(pow(10, -1.3), 0.28), pow(pow(10, 0.22), 0.28) * 0.5)
		
		var new_wormhole = addWormhole(identifier_count, str(get_random_wormhole_name()), hook.get_identifier(), new_distance, global_data.get_randf(minimum_speed, maximum_speed), (radius / 109.1), dest_system, {"color": Color.WEB_PURPLE})
		get_body_from_identifier(new_wormhole).rotation = deg_to_rad(global_data.get_randf(0,360))
		if dest_system == previous_system:
			get_body_from_identifier(new_wormhole).is_disabled = true
		#FORCE SETS WORMHOLE COLOUR TO PURPLE!!!!!!!!!!!!
		post_gen_location_candidates.remove_at(post_gen_location_candidates.find(location))
	pass

func generateRandomStations():
	for station in global_data.get_randi(2, 5):
		var location = post_gen_location_candidates.pick_random()
		var hook = get_body_from_identifier(location.front())
		var i = location.back()
		
		#whole bunch of stuff borrowed from generateRandomWeightedBodies
		var new_distance: float = hook.radius + pow(hook.radius, 1/3) + ((hook.radius * 10) * i)
		var orbit_speed_multiplier: float
		if hook.orbit_speed > 0: orbit_speed_multiplier = ((hook.orbit_speed * 109.1) + 1)
		else: orbit_speed_multiplier = 1
		
		var minimum_speed: float = ((sqrt(47*(hook.metadata.get("mass")) / hook.radius)) / time) / (new_distance / 100) * orbit_speed_multiplier
		var maximum_speed: float = ((sqrt((2*47*hook.metadata.get("mass")) / hook.radius)) / time) / (new_distance / 100) * orbit_speed_multiplier
		
		#any size between the smallest terrestrial world, to half the size of the largest terrestrial world!
		var radius = global_data.get_randf(pow(pow(10, -1.3), 0.28), pow(pow(10, 0.22), 0.28) * 0.5)
		
		var station_classification = stationAPI.STATION_CLASSIFICATIONS.values().pick_random()
		var percentage_markup = global_data.get_randi(50, 200)
		
		var new_station = addStation(identifier_count, str(get_random_station_name()), hook.get_identifier(), new_distance, global_data.get_randf(minimum_speed, maximum_speed), (radius / 109.1), station_classification, percentage_markup)
		get_body_from_identifier(new_station).rotation = deg_to_rad(global_data.get_randf(0,360))
		
		post_gen_location_candidates.remove_at(post_gen_location_candidates.find(location))
	pass

func generateRandomWeightedAnomalies():
	pass

func addBody(id: int, d_name: String, hook_identifier: int, distance: float, orbit_speed: float, radius: float, metadata: Dictionary = {}):
	var body = bodyAPI.new()
	body.set_identifier(id)
	identifier_count += 1
	body.set_display_name(d_name)
	body.hook_identifier = hook_identifier
	body.distance = distance
	body.orbit_speed = orbit_speed
	body.radius = radius
	if metadata:
		body.metadata = metadata
	body.current_variation = bodyAPI.VARIATIONS.values().pick_random()
	bodies.append(body)
	return body.get_identifier()

func addWormhole(id: int, d_name: String, hook_identifier: int, distance: float, orbit_speed: float, radius: float, destination_system: starSystemAPI, metadata: Dictionary = {}):
	var wormhole = wormholeAPI.new()
	wormhole.set_identifier(id)
	identifier_count += 1
	wormhole.set_display_name(d_name)
	wormhole.hook_identifier = hook_identifier
	wormhole.distance = distance
	wormhole.orbit_speed = orbit_speed
	wormhole.radius = radius
	wormhole.destination_system = destination_system
	if metadata:
		wormhole.metadata = metadata
	bodies.append(wormhole)
	return wormhole.get_identifier()

func addStation(id: int, d_name: String, hook_identifier: int, distance: float, orbit_speed: float, radius: float, station_classification, sell_percentage_of_market_price, metadata: Dictionary = {}):
	var station = stationAPI.new()
	station.set_identifier(id)
	identifier_count += 1
	station.set_display_name(d_name)
	station.hook_identifier = hook_identifier
	station.distance = distance
	station.orbit_speed = orbit_speed
	station.radius = radius
	station.station_classification = station_classification
	station.sell_percentage_of_market_price = sell_percentage_of_market_price
	if metadata:
		station.metadata = metadata
	bodies.append(station)
	return station.get_identifier()

func addStationaryBody(id: int, d_name: String, hook_identifier, radius: float, metadata: Dictionary = {}):
	var body = bodyAPI.new()
	body.set_identifier(id)
	identifier_count += 1
	body.set_display_name(d_name)
	if hook_identifier:
		body.hook_identifier = hook_identifier
	body.radius = radius
	if metadata:
		body.metadata = metadata
	body.current_variation = bodyAPI.VARIATIONS.values().pick_random()
	bodies.append(body)
	return body.get_identifier()

func removeBody(id: int):
	for body in bodies:
		if body.get_identifier() == id:
			bodies.erase(body.get_identifier())
	pass

func updateBodyPosition(id: int, delta):
	var body = get_body_from_identifier(id)
	if body and body.hook_identifier != null:
		var hook = get_body_from_identifier(body.hook_identifier)
		if hook:
			body.position = hook.position
			if body.orbit_speed != 0 and body.distance != 0:
				var dir = Vector2.UP.rotated(body.rotation)
				body.rotation += body.orbit_speed * delta
				body.position = body.position + (dir * body.distance)
	pass

func get_random_body():
	return bodies.pick_random()

func get_random_planet():
	var planets: Array = []
	for body in bodies:
		if body.is_planet():
			planets.append(body)
	return planets

func get_first_star():
	for body in bodies:
		if body.is_star():
			return body

func get_body_from_identifier(id: int):
	var get_body: bodyAPI
	for body in bodies:
		if body.get_identifier() == id:
			get_body = body
			break
	return get_body

func get_bodies_with_hook_identifier(id: int):
	var bodies_with_requested_hook_identifier: Array = []
	for body in bodies:
		if body.hook_identifier == id:
			bodies_with_requested_hook_identifier.append(body)
	return bodies_with_requested_hook_identifier

func get_bodies_with_metadata_key(metadata_key: String):
	var return_bodies: Array = []
	for body in bodies:
		if body.metadata.has(metadata_key):
			return_bodies.append(body)
	return return_bodies

func get_wormholes():
	var wormholes: Array[wormholeAPI] = []
	for body in bodies:
		if body is wormholeAPI:
			wormholes.append(body)
	return wormholes

func get_stations():
	var stations: Array[stationAPI] = []
	for body in bodies:
		if body is stationAPI:
			stations.append(body)
	return stations

func get_wormhole_with_destination_system(dest_system: starSystemAPI):
	for body in bodies:
		if body.is_wormhole():
			if body.destination_system == dest_system:
				return body

func is_civilized():
	for body in bodies:
		if body is stationAPI:
			return true
	return false




#CONSOLIDATE ALL THESE INTO ONE FUNCTION AT SOME POINT \/\/\/\/

func get_random_star_name():
	var name_candidates: Array = []
	var file = FileAccess.open("res://Data/Name Data/star_names.txt", FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line()
		if not line.is_empty():
			name_candidates.append(line)
	file.close()
	var pick = name_candidates.pick_random()
	if randf() >= 0.75:
		pick = str(pick + " " + get_random_flair())
	return pick

func get_random_planet_name():
	var name_candidates: Array = []
	var file = FileAccess.open("res://Data/Name Data/planet_names.txt", FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line()
		if not line.is_empty():
			name_candidates.append(line)
	file.close()
	var pick = name_candidates.pick_random()
	if randf() >= 0.75:
		pick = str(pick + " " + get_random_flair())
	return pick

func get_random_asteroid_belt_name():
	var name_candidates: Array = []
	var file = FileAccess.open("res://Data/Name Data/asteroid_belt_names.txt", FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line()
		if not line.is_empty():
			name_candidates.append(line)
	file.close()
	return name_candidates.pick_random()

func get_random_wormhole_name():
	var name_candidates: Array = []
	var file = FileAccess.open("res://Data/Name Data/wormhole_names.txt", FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line()
		if not line.is_empty():
			name_candidates.append(line)
	file.close()
	return name_candidates.pick_random()

func get_random_station_name():
	var name_candidates: Array = []
	var file = FileAccess.open("res://Data/Name Data/station_names.txt", FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line()
		if not line.is_empty():
			name_candidates.append(line)
	file.close()
	return name_candidates.pick_random()

func get_random_flair():
	var flair_candidates: Array = []
	var flair_file = FileAccess.open("res://Data/Name Data/name_flair.txt", FileAccess.READ)
	while not flair_file.eof_reached():
		var line = flair_file.get_line()
		if not line.is_empty():
			flair_candidates.append(line)
	flair_file.close()
	return flair_candidates.pick_random()
