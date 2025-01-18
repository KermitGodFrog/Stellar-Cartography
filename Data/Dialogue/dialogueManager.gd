extends Node
#dialogueManager is an exception to common pausing best practice because it is always active
var _pause_mode: game_data.PAUSE_MODES = game_data.PAUSE_MODES.NONE:
	set(value):
		_pause_mode = value
		_on_pause_mode_changed(value)
signal queuePauseMode(new_mode: game_data.PAUSE_MODES)
signal setPauseMode(new_mode: game_data.PAUSE_MODES)
func _on_pause_mode_changed(value):
	match value:
		game_data.PAUSE_MODES.NONE:
			dialogue.hide()
		game_data.PAUSE_MODES.DIALOGUE:
			dialogue.show()
	pass



signal onCloseDialog(with_return_state)
signal addDialogueMemoryPair(key, value)

signal addPlayerValue(amount: int)
signal addPlayerHullStress(amount: int)
signal removePlayerHullStress(amount: int)
signal addPlayerMorale(amount: int)
signal removePlayerMorale(amount: int)
signal killCharacterWithOccupation(occupation: characterAPI.OCCUPATIONS)
signal foundBody(id: int)

signal TUTORIALSetIngressOverride(value: bool)
signal TUTORIALSetOmissionOverride(value: bool)
signal TUTORIALPlayerWin()

var dialogue_memory: Dictionary = {} #memory that is added by any query, and is always accessible indefinitely. from worldAPI dialogue_memory which is sent via game.gd
var tree_access_memory: Dictionary #memory that is explicitely added by a query via add_tree_access() - is added to any query until the dialog is closed
enum QUERY_TYPES {BEST, ALL, RAND_BEST, FULL_BEST}

#for populating query data
var system: starSystemAPI
var player: playerAPI
var character_lookup_dictionary: Dictionary = {}

var rules: Array[responseRule] = []
enum POINTERS {RULE, CRITERIA, APPLY_FACTS, TRIGGER_FUNCTIONS, TRIGGER_RULES, QUERY_ALL_CONCEPT, QUERY_BEST_CONCEPT, QUERY_RAND_BEST_CONCEPT, QUERY_FULL_BEST_CONCEPT, OPTIONS, TEXT}

var _achievements_array: Array[achievement] = []

@onready var dialogue = $dialogue/dialogue_control

func _ready():
	addDialogueMemoryPair.connect(_on_add_dialogue_memory_pair) #im connecitng this signal to its own script because im not sure if it does anything else / is important
	
	var csv_rules = FileAccess.open("res://Data/Dialogue/rules.txt", FileAccess.READ)
	var current_pointer: POINTERS = POINTERS.RULE
	var current_line: int = 0
	var new_rule: responseRule = null
	
	while not csv_rules.eof_reached():
		var line = csv_rules.get_csv_line()
		current_line += 1
		if current_line == 1: continue
		if line.is_empty(): continue
		
		for cell in line:
			match POINTERS.find_key(current_pointer):
				"RULE":
					if new_rule != null:
						if new_rule.is_configured():
							rules.append(new_rule)
							print("ADDING NEW RULE: ", new_rule.get_name())
					new_rule = responseRule.new()
					new_rule.set_name(cell)
				"CRITERIA":
					var dict = convert_to_dictionary(cell)
					if not dict.is_empty():
						new_rule.criteria = dict
				"APPLY_FACTS":
					var dict = convert_to_dictionary(cell)
					if not dict.is_empty():
						new_rule.apply_facts = dict
				"TRIGGER_FUNCTIONS":
					var dict = convert_to_dictionary(cell)
					if not dict.is_empty():
						new_rule.trigger_functions = dict
				"TRIGGER_RULES":
					var array = convert_to_array(cell)
					if not array.is_empty():
						new_rule.trigger_rules = array
				"QUERY_ALL_CONCEPT":
					var array = convert_to_array(cell)
					if not array.is_empty():
						new_rule.query_all_concept = array
				"QUERY_BEST_CONCEPT":
					var array = convert_to_array(cell)
					if not array.is_empty():
						new_rule.query_best_concept = array
				"QUERY_RAND_BEST_CONCEPT":
					var array = convert_to_array(cell)
					if not array.is_empty():
						new_rule.query_rand_best_concept = array
				"QUERY_FULL_BEST_CONCEPT":
					var array = convert_to_array(cell)
					if not array.is_empty():
						new_rule.query_full_best_concept = array
				"OPTIONS":
					var dict = convert_to_dictionary(cell)
					if not dict.is_empty():
						new_rule.options = dict
				"TEXT":
					if not cell.is_empty():
						new_rule.text = cell
			
			if POINTERS.values()[current_pointer] == POINTERS.values().back(): current_pointer = POINTERS.values().front()
			else: current_pointer = POINTERS.values()[current_pointer + 1]
	
	csv_rules.close()
	pass

func convert_to_dictionary(cell : String) -> Dictionary:
	if cell.left(1) == "#": return {}
	
	var parts = global_data.split_string_multiple_delimeters(cell, [",", ":"])
	var corrected_parts: Array = []
	for part: String in parts: corrected_parts.append(part.dedent())
	
	if global_data.is_even(corrected_parts.size()):
		var new_dictionary: Dictionary = {}
		var next_key: int = 0
		
		for i in corrected_parts.size():
			if i == next_key:
				var value: String = corrected_parts[i + 1]
				var type_corrected_value = value
				
				if value.is_valid_int():
					type_corrected_value = value.to_int()
				if value.is_valid_float():
					type_corrected_value = value.to_float()
				if value == "null":
					type_corrected_value = null
				if value == "true":
					type_corrected_value = true
				if value == "false":
					type_corrected_value = false
				
				#>int or <float et al cannot go here, must be calculated at runtime
				
				new_dictionary[corrected_parts[i]] = type_corrected_value
				if corrected_parts.size() < (i + 2): break
				next_key += 2
		return new_dictionary
	else: return {}

func convert_to_array(cell : String) -> Array[String]:
	if cell.left(1) == "#": return []
	
	var parts = cell.split(",", false)
	var corrected_parts: Array[String] = []
	for part: String in parts: corrected_parts.append(part.dedent())
	
	if not corrected_parts.is_empty():
		return corrected_parts
	else: return []


func speak(calling: Node, incoming_query: responseQuery, populate_data: bool = true, type: QUERY_TYPES = QUERY_TYPES.BEST):
	if not incoming_query.tree_access_facts.is_empty():
		tree_access_memory.merge(incoming_query.tree_access_facts, true)
	
	if populate_data:
		incoming_query.populateWithPlayerData(player)
		incoming_query.populateWithSystemData(system)
		incoming_query.populateWithDialogueMemoryData(dialogue_memory)
		incoming_query.populateWithTreeAccessMemoryData(tree_access_memory)
		incoming_query.populateWithWorldData()
	
	get_send_ranked_achievements(incoming_query)
	
	print("QUERY HANDLER: ", calling, " QUERYING ", incoming_query.facts)
	
	match type:
		QUERY_TYPES.BEST:
			
			var relevant_rules = get_relevant_rules(incoming_query)
			
			var ranked_rules: Dictionary = {}
			for rule in relevant_rules:
				incoming_query.facts["randf_EXCLUSIVE"] = randf()
				incoming_query.facts["randi_EXCLUSIVE"] = randi()
				var matches: int = get_rule_matches(rule, incoming_query)
				ranked_rules[rule] = matches
			
			for rule in ranked_rules: #DEBUG!!!!!!!!!!!!!!!!!!!!!!!
				print_rich(str("[color=GREEN]", rule.get_name(), " : ", "[color=PINK]", ranked_rules.get(rule), " (B)"))
			
			var values = ranked_rules.values()
			var max_value = values.max()
			
			incoming_query.facts.erase("randf_EXCLUSIVE")
			incoming_query.facts.erase("randi_EXCLUSIVE")
			
			var matched_rule = ranked_rules.find_key(max_value) #find_key always gets the FIRST key in added-order. as rules are added in order of the rules.csv file, rules towards the top of the .csv will ALWAYS be selected, even if theres other rules with the same number of matches further down. 
			if matched_rule: trigger_rule(calling, matched_rule, incoming_query)
			
		QUERY_TYPES.ALL: #FOR 'QUERY ALL CONCEPT'
			
			var relevant_rules = get_relevant_rules(incoming_query)
			
			var matched_rules: Array[responseRule] = []
			for rule in relevant_rules:
				incoming_query.facts["randf_EXCLUSIVE"] = randf()
				incoming_query.facts["randi_EXCLUSIVE"] = randi()
				var matches: int = get_rule_matches(rule, incoming_query)
				if matches == rule.criteria.size():
					matched_rules.append(rule)
			
			for rule in matched_rules: #DEBUG!!!!!!!!!!!!!!!!!!!!!!!
				print_rich(str("[color=GREEN]", rule.get_name(), " : ", "[color=PINK]", rule.criteria.size(), " (ALL)"))
			
			incoming_query.facts.erase("randf_EXCLUSIVE")
			incoming_query.facts.erase("randi_EXCLUSIVE")
			
			for matched_rule in matched_rules:
				trigger_rule(calling, matched_rule, incoming_query)
			
		QUERY_TYPES.RAND_BEST:
			
			var relevant_rules = get_relevant_rules(incoming_query)
			
			var ranked_rules: Dictionary = {}
			for rule in relevant_rules:
				incoming_query.facts["randf_EXCLUSIVE"] = randf()
				incoming_query.facts["randi_EXCLUSIVE"] = randi()
				var matches: int = get_rule_matches(rule, incoming_query)
				ranked_rules[rule] = matches
			
			for rule in ranked_rules: #DEBUG!!!!!!!!!!!!!!!!!!!!!!!
				print_rich(str("[color=GREEN]", rule.get_name(), " : ", "[color=PINK]", ranked_rules.get(rule), " (RB)"))
			
			var rules_with_max_matches: Array = []
			
			var values = ranked_rules.values()
			var max_value = values.max()
			for i in values.size():
				var key_with_max_value = ranked_rules.find_key(max_value)
				if key_with_max_value != null:
					rules_with_max_matches.append(key_with_max_value)
					ranked_rules.erase(key_with_max_value)
				else: break
			
			incoming_query.facts.erase("randf_EXCLUSIVE")
			incoming_query.facts.erase("randi_EXCLUSIVE")
			
			var random = RandomNumberGenerator.new()
			random.set_seed(incoming_query.facts.get("custom_seed", randi()))
			var random_index = random.randi_range(0, rules_with_max_matches.size() - 1)
			
			var matched_rule: responseRule = rules_with_max_matches[random_index]
			if matched_rule: trigger_rule(calling, matched_rule, incoming_query)
			
		QUERY_TYPES.FULL_BEST:
			pass
	pass

func get_rule_matches(rule, incoming_query) -> int: #I should be executed for this.
	var matches: int = 0
	for fact in incoming_query.facts:
		if rule.criteria.has(fact):
			if typeof(rule.criteria.get(fact)) == TYPE_STRING:
				
				
				if rule.criteria.get(fact).begins_with("<="):
					if incoming_query.facts.get(fact) <= rule.criteria.get(fact).trim_prefix("<=").to_float():
						matches += 1
					else: continue
				elif rule.criteria.get(fact).begins_with(">="):
					if incoming_query.facts.get(fact) >= rule.criteria.get(fact).trim_prefix(">=").to_float():
						matches += 1
					else: continue
				elif rule.criteria.get(fact).begins_with("<"):
					if incoming_query.facts.get(fact) < rule.criteria.get(fact).trim_prefix("<").to_float():
						matches += 1
					else: continue
				elif rule.criteria.get(fact).begins_with(">"):
					if incoming_query.facts.get(fact) > rule.criteria.get(fact).trim_prefix(">").to_float():
						matches += 1
					else: continue
				else:
					if incoming_query.facts.get(fact) == rule.criteria.get(fact):
						matches += 1
					else: continue
					
					
			else:
				if incoming_query.facts.get(fact) == rule.criteria.get(fact):
					matches += 1
				else: continue
		else: continue
	return matches

func get_relevant_rules(incoming_query: responseQuery) -> Array[responseRule]:
	var relevant_rules: Array[responseRule] = []
	if incoming_query.facts.has("concept"):
		for rule in rules:
			if rule.criteria.has("concept"):
				if rule.criteria.get("concept") == incoming_query.facts.get("concept"):
					relevant_rules.append(rule)
		if relevant_rules.size() > 0:
			return relevant_rules
		else:
			print_debug("!! ERROR: NO RELEVANT RULES, RETURNING ALL RULES !!")
			return rules
	else:
		print_debug("!! ERROR: NO RELEVANT RULES, RETURNING ALL RULES !!")
		return rules

func convert_string_number(string_number: String):
	if string_number.is_valid_int():
		return string_number.to_int()
	elif string_number.is_valid_float():
		return string_number.to_float()
	return string_number


func trigger_rule(calling: Node, rule: responseRule, incoming_query: responseQuery):
	print("QUERY HANDLER: ", calling, " TRIGGERING RULE ", rule.get_name())
	#apply_facts: \\\\\\\\\\\\\
	for fact in rule.apply_facts:
		emit_signal("addDialogueMemoryPair", fact, rule.apply_facts.get(fact))
		print("QUERY HANDLER: ", calling, " APPLYING FACT ", fact)
	
	#trigger_functions: \\\\\\\\\\\\\
	for trigger_function in rule.trigger_functions:
		if has_method(trigger_function):
			var values = rule.trigger_functions.get(trigger_function)
			if values != null: 
				match typeof(values):
					TYPE_ARRAY:
						print("QUERY HANDLER: ", calling, " TRIGGERING FUNCTION ", trigger_function)
						call(trigger_function, values)
					TYPE_STRING:
						print("QUERY HANDLER: ", calling, " TRIGGERING FUNCTION ", trigger_function)
						call(trigger_function, convert_text_with_custom_tags(values, incoming_query))
					_:
						print("QUERY HANDLER: ", calling, " TRIGGERING FUNCTION ", trigger_function)
						call(trigger_function, values)
			else:
				call(trigger_function)
	
	#trigger_rules: \\\\\\\\\\\\\
	for _trigger_rule in rule.trigger_rules:
		for r in rules:
			if r.get_name() == _trigger_rule:
				trigger_rule(calling, r, incoming_query)
	
	for concept in rule.query_all_concept:
		var new_query = responseQuery.new()
		new_query.add("concept", concept)
		speak(calling, new_query, true, QUERY_TYPES.ALL)
	
	for concept in rule.query_best_concept:
		var new_query = responseQuery.new()
		new_query.add("concept", concept)
		speak(calling, new_query, true, QUERY_TYPES.BEST)
	
	for concept in rule.query_rand_best_concept:
		var new_query = responseQuery.new()
		new_query.add("concept", concept)
		speak(calling, new_query, true, QUERY_TYPES.RAND_BEST)
	
	for concept in rule.query_full_best_concept:
		var new_query = responseQuery.new()
		new_query.add("concept", concept)
		speak(calling, new_query, true, QUERY_TYPES.FULL_BEST)
	
	#text & options \\\\\\\\\\\\\
	if rule.text: dialogue.add_text(convert_text_with_custom_tags(rule.text, incoming_query))
	if rule.options: dialogue.add_options(rule.options)
	pass

func convert_text_with_custom_tags(text: String, query: responseQuery) -> String:
	#i feel like this is veryyy slloooowwwwwwwww.......
	for fact in query.facts:
		text = text.replace("$%s" % fact, "%s" % query.facts.get(fact, "ERR"))
	#text = text.replace("$PLANET_NAME", query.facts.get("planet_name", "CONVERT_TEXT_WITH_CUSTOM_TAGS_ERR"))
	return text

func _on_add_dialogue_memory_pair(key,value) -> void: #im connecitng this signal to its own script because im not sure if it does anything else / is important
	dialogue_memory[key] = value
	pass



func receive_updated_achievements_array(updated_achievements_array: Array[achievement]):
	_achievements_array = updated_achievements_array
	pass

func get_send_ranked_achievements(incoming_query) -> void:
	var ranked_achievements: Dictionary = {}
	for _achievement in _achievements_array:
		var rule = responseRule.new()
		rule.criteria = _achievement.dialogue_criteria
		ranked_achievements[_achievement] = get_rule_matches(rule, incoming_query)
	
	get_tree().call_group("achievementManager", "receive_ranked_achievements", ranked_achievements)
	pass



func openDialog():
	clearAll()
	dialogue.clear_image()
	emit_signal("queuePauseMode", game_data.PAUSE_MODES.DIALOGUE)
	pass

func closeDialog(with_return_state = null):
	tree_access_memory = {}
	emit_signal("onCloseDialog", with_return_state)
	emit_signal("setPauseMode", game_data.PAUSE_MODES.NONE)
	pass

func clearText():
	dialogue.clear_text()
	pass

func clearOptions():
	dialogue.clear_options()
	pass

func clearAll():
	dialogue.clear_all()
	pass

func addValueWithFlair(amount: int):
	emit_signal("addPlayerValue", amount)
	dialogue.add_text(str("[color=green](Gained ", amount, " nanites in data value) [/color]"))
	playSoundEffect("dialogue_success.wav") #easier than putting it in every single rule?
	pass

func addHullStressWithFlair(amount: int):
	emit_signal("addPlayerHullStress", amount)
	dialogue.add_text(str("[color=red](Plus ", amount, "% hull stress) [/color]"))
	playSoundEffect("dialogue_failure.wav")
	pass

func removeHullStressWithFlair(amount: int):
	emit_signal("removePlayerHullStress", amount)
	dialogue.add_text(str("[color=green](Minus ", amount, "% hull stress) [/color]"))
	playSoundEffect("dialogue_success.wav")
	pass

func addMoraleWithFlair(amount: int):
	emit_signal("addPlayerMorale", amount)
	dialogue.add_text(str("[color=green](Plus ", amount, "% morale) [/color]"))
	playSoundEffect("dialogue_success.wav")
	pass

func removeMoraleWithFlair(amount: int):
	emit_signal("removePlayerMorale", amount)
	dialogue.add_text(str("[color=red](Minus ", amount, "% morale) [/color]"))
	playSoundEffect("dialogue_failure.wav")
	pass

func killCharacterWithFlair(occupation: characterAPI.OCCUPATIONS):
	emit_signal("killCharacterWithOccupation", occupation)
	print(character_lookup_dictionary)
	var lookup = character_lookup_dictionary.get(occupation, " ")
	dialogue.add_text(str("[color=red](", characterAPI.OCCUPATIONS.find_key(occupation).replace("_", " "), " ", lookup, " is dead) [/color]"))
	playSoundEffect("dialogue_failure.wav")
	pass

func setImage(path: String):
	dialogue.set_image(path)
	pass

func clearImage():
	dialogue.clear_image()

func playSoundEffect(path: String) -> void:
	dialogue.play_sound_effect(path)
	pass

func discoverRandomBodyWithFlair() -> void:
	var undiscovered_bodies: Array[bodyAPI] = []
	for body in system.bodies:
		if not (body.is_star() or body.is_station()):
			if not body.is_known:
				undiscovered_bodies.append(body)
	if undiscovered_bodies.size() > 0:
		var body: bodyAPI = undiscovered_bodies.pick_random()
		emit_signal("foundBody", body.get_identifier())
		dialogue.add_text(str("[color=green](Gained scan data for ", body.get_display_name(), ") [/color]"))
		playSoundEffect("dialogue_success.wav") #easier than putting it in every single rule?
	else:
		dialogue.add_text(str("[color=green](Gained no new scan data) [/color]"))
	pass



func _TUTORIALSetIngressOverride(value: bool):
	emit_signal("TUTORIALSetIngressOverride", value)
	pass

func _TUTORIALSetOmissionOverride(value: bool):
	emit_signal("TUTORIALSetOmissionOverride", value)
	pass

func _TUTORIALPlayerWin():
	emit_signal("TUTORIALPlayerWin")
	pass
