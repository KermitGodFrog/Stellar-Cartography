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

signal openLRS()
signal openGLS()

signal decreasePlayerBalance(amount: int)
signal addPlayerValue(amount: int)
signal addPlayerHullStress(amount: int)
signal removePlayerHullStress(amount: int)
signal addPlayerMorale(amount: int)
signal removePlayerMorale(amount: int)
signal killCharacterWithOccupation(occupation: characterAPI.OCCUPATIONS)
signal foundBody(id: int)
signal addPlayerMutinyBacking(amount: int)
signal upgradeShip(_upgrade_idx: playerAPI.UPGRADE_ID, _cost: int)
signal rollNavBuoy(anomaly_seed: int)
signal TUTORIALSetIngressOverride(value: bool)
signal TUTORIALSetOmissionOverride(value: bool)
signal TUTORIALPlayerWin()

var dialogue_memory: Dictionary = {} #memory that is added by any query, and is always accessible indefinitely. from worldAPI dialogue_memory which is sent via game.gd
var tree_access_memory: Dictionary #memory that is explicitely added by a query via add_tree_access() - is added to any query until the dialog is closed
enum QUERY_TYPES {BEST, ALL, RAND_BEST, OLD_BEST}

#for populating query data
var system: starSystemAPI
var player: playerAPI

var rules: Array[responseRule] = []
enum POINTERS {RULE, CRITERIA, APPLY_FACTS, TRIGGER_FUNCTIONS, TRIGGER_RULES, QUERY_ALL_CONCEPT, QUERY_BEST_CONCEPT, QUERY_RAND_BEST_CONCEPT, QUERY_FULL_BEST_CONCEPT, OPTIONS, TEXT}

var _achievements_array: Array[responseAchievement] = []

@onready var dialogue = $dialogue/dialogue_control

func _ready() -> void:
	addDialogueMemoryPair.connect(_on_add_dialogue_memory_pair) #im connecitng this signal to its own script because im not sure if it does anything else / is important
	clear_and_load_rules()
	pass

func clear_and_load_rules() -> void:
	rules.clear()
	
	var csv_rules = FileAccess.open("res://Data/Dialogue/rules.txt", FileAccess.READ)
	var current_pointer: POINTERS = POINTERS.RULE
	var current_line: int = 0
	var current_rule: int = 0
	var new_rule: responseRule = null
	var eof_override: bool = true
	
	while (not csv_rules.eof_reached()) or eof_override:
		if csv_rules.eof_reached():
			eof_override = false #setup to read an extra line, as eof_reached() returns true when there is still a line left
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
							current_rule += 1
							print("ADDING NEW RULE > %d > %s" % [current_rule, new_rule.get_name()])
					
					var text = convert_to_string(cell)
					if not text.is_empty():
						new_rule = responseRule.new()
						new_rule.set_name(text)
					else:
						new_rule = null
				"CRITERIA":
					var dict = convert_to_dictionary(cell)
					if not dict.is_empty() and new_rule != null:
						new_rule.criteria = dict
				"APPLY_FACTS":
					var dict = convert_to_dictionary(cell)
					if not dict.is_empty() and new_rule != null:
						new_rule.apply_facts = dict
				"TRIGGER_FUNCTIONS":
					var dict = convert_to_dictionary(cell)
					if not dict.is_empty() and new_rule != null:
						new_rule.trigger_functions = dict
				"TRIGGER_RULES":
					var array = convert_to_array(cell)
					if not array.is_empty() and new_rule != null:
						new_rule.trigger_rules = array
				"QUERY_ALL_CONCEPT":
					var array = convert_to_array(cell)
					if not array.is_empty() and new_rule != null:
						new_rule.query_all_concept = array
				"QUERY_BEST_CONCEPT":
					var array = convert_to_array(cell)
					if not array.is_empty() and new_rule != null:
						new_rule.query_best_concept = array
				"QUERY_RAND_BEST_CONCEPT":
					var array = convert_to_array(cell)
					if not array.is_empty() and new_rule != null:
						new_rule.query_rand_best_concept = array
				"QUERY_OLD_BEST_CONCEPT":
					var array = convert_to_array(cell)
					if not array.is_empty() and new_rule != null:
						new_rule.query_old_best_concept = array
				"OPTIONS":
					var dict = convert_to_dictionary(cell)
					if not dict.is_empty() and new_rule != null:
						new_rule.options = dict
				"TEXT":
					var text = convert_to_string(cell)
					if not text.is_empty() and new_rule != null:
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

func convert_to_string(cell : String) -> String:
	if cell.left(1) == "#": return String()
	return cell




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
				if rule.criteria.size() == matches:
					ranked_rules[rule] = matches 
			
			for rule in ranked_rules:
				print_rich(str("[color=GREEN]", rule.get_name(), " : ", "[color=PINK]", ranked_rules.get(rule), " (B)"))
			
			var values = ranked_rules.values()
			var max_value = values.max()
			
			incoming_query.facts.erase("randf_EXCLUSIVE")
			incoming_query.facts.erase("randi_EXCLUSIVE")
			
			var matched_rule = ranked_rules.find_key(max_value) #find_key always gets the FIRST key in added-order. as rules are added in order of the rules.csv file, rules towards the top of the .csv will ALWAYS be selected, even if theres other rules with the same number of matches further down. 
			if matched_rule != null: trigger_rule(calling, matched_rule, incoming_query)
			
		QUERY_TYPES.ALL: #FOR 'QUERY ALL CONCEPT'
			
			var relevant_rules = get_relevant_rules(incoming_query)
			
			var matched_rules: Array[responseRule] = []
			for rule in relevant_rules:
				incoming_query.facts["randf_EXCLUSIVE"] = randf()
				incoming_query.facts["randi_EXCLUSIVE"] = randi()
				var matches: int = get_rule_matches(rule, incoming_query)
				if rule.criteria.size() == matches:
					matched_rules.append(rule)
			
			for rule in matched_rules:
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
				if rule.criteria.size() == matches:
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
			
			#print_rich("[color=RED]", rules_with_max_matches, "[/color]")
			incoming_query.facts.erase("randf_EXCLUSIVE")
			incoming_query.facts.erase("randi_EXCLUSIVE")
			
			if rules_with_max_matches.size() > 0:
				var random = RandomNumberGenerator.new()
				random.set_seed(incoming_query.facts.get("seed", randi()))
				var random_index = random.randi_range(0, rules_with_max_matches.size() - 1)
				
				var matched_rule: responseRule = rules_with_max_matches[random_index]
				if matched_rule != null: trigger_rule(calling, matched_rule, incoming_query)
			
		QUERY_TYPES.OLD_BEST:
			
			var relevant_rules = get_relevant_rules(incoming_query)
			
			var ranked_rules: Dictionary = {}
			for rule in relevant_rules:
				incoming_query.facts["randf_EXCLUSIVE"] = randf()
				incoming_query.facts["randi_EXCLUSIVE"] = randi()
				var matches: int = get_rule_matches(rule, incoming_query)
				ranked_rules[rule] = matches
			
			for rule in ranked_rules:
				print_rich(str("[color=GREEN]", rule.get_name(), " : ", "[color=PINK]", ranked_rules.get(rule), " (B)"))
			
			var values = ranked_rules.values()
			var max_value = values.max()
			
			incoming_query.facts.erase("randf_EXCLUSIVE")
			incoming_query.facts.erase("randi_EXCLUSIVE")
			
			var matched_rule = ranked_rules.find_key(max_value) #find_key always gets the FIRST key in added-order. as rules are added in order of the rules.csv file, rules towards the top of the .csv will ALWAYS be selected, even if theres other rules with the same number of matches further down. 
			if matched_rule != null: trigger_rule(calling, matched_rule, incoming_query)
			
	pass

func get_rule_matches(rule, incoming_query) -> int: #I should be executed for this.
	var matches: int = 0
	
	#(probably very inefficient) code to make criteria values which are 'false' result in a match if their key does not exist in incoming_query facts
	for c_key in rule.criteria:
		var c_value = rule.criteria.get(c_key)
		if typeof(c_value) == TYPE_BOOL:
			if c_value == false:
				if not incoming_query.facts.has(c_key):
					matches += 1
	
	for fact in incoming_query.facts:
		if rule.criteria.has(fact):
			if typeof(rule.criteria.get(fact)) == TYPE_STRING:
				var converted_value = replace_fact_references(rule.criteria.get(fact), incoming_query)
				
				if converted_value.begins_with("<="):
					if incoming_query.facts.get(fact) <= converted_value.trim_prefix("<=").to_float():
						matches += 1
					else: continue
				elif converted_value.begins_with(">="):
					if incoming_query.facts.get(fact) >= converted_value.trim_prefix(">=").to_float():
						matches += 1
					else: continue
				elif converted_value.begins_with("<"):
					if incoming_query.facts.get(fact) < converted_value.trim_prefix("<").to_float():
						matches += 1
					else: continue
				elif converted_value.begins_with(">"):
					if incoming_query.facts.get(fact) > converted_value.trim_prefix(">").to_float():
						matches += 1
					else: continue
				else:
					if incoming_query.facts.get(fact) == converted_value:
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
					TYPE_STRING:
						print("QUERY HANDLER: ", calling, " TRIGGERING FUNCTION ", trigger_function)
						call(trigger_function, replace_fact_references(values, incoming_query))
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
	
	for concept in rule.query_old_best_concept:
		var new_query = responseQuery.new()
		new_query.add("concept", concept)
		speak(calling, new_query, true, QUERY_TYPES.OLD_BEST)
	
	#text & options \\\\\\\\\\\\\
	if rule.text: dialogue.add_text(replace_fact_references(rule.text, incoming_query))
	if rule.options: dialogue.add_options(rule.options)
	pass

func replace_fact_references(text: String, query: responseQuery) -> String:
	var a: PackedStringArray = []
	for fact in query.facts:
		a.append(fact)
	
	var regex_args = "|\\$".join(a)
	var formatted_regex_args = "%s%s" % ["\\$", regex_args]
	var pattern = "(%s)(?![_\\w])" % formatted_regex_args
	
	var regex = RegEx.new()
	regex.compile(pattern)
	
	var results = regex.search_all(text)
	var offset: int = 0
	for result in results:
		var start: int = result.get_start()
		var end: int = result.get_end()
		var length: int = end - start
		var fact = result.get_string().right(-1)
		var replacement = query.facts.get(fact)
		
		var new_text: String = str(text.substr(0, start + offset), replacement, text.substr(end + offset))
		
		offset += str(replacement).length() - length
		text = new_text
	
	return text


func _on_add_dialogue_memory_pair(key,value) -> void: #im connecitng this signal to its own script because im not sure if it does anything else / is important
	dialogue_memory[key] = value
	pass

func receive_updated_achievements_array(updated_achievements_array: Array[responseAchievement]):
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

func openLRSApplicable():
	emit_signal("openLRS")
	pass

func openGLSApplicable():
	emit_signal("openGLS")
	pass

func closeDialog(with_return_state = null):
	tree_access_memory = {}
	emit_signal("onCloseDialog", with_return_state)
	emit_signal("setPauseMode", game_data.PAUSE_MODES.NONE)
	dialogue.stop_music()
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

func decreaseBalanceWithFlair(amount):
	if typeof(amount) == TYPE_STRING:
		amount = amount.to_int()
	emit_signal("decreasePlayerBalance", amount)
	dialogue.add_text("[color=red](Lost %d nanites) [/color]" % amount)
	pass

func addValueWithFlair(amount: int):
	emit_signal("addPlayerValue", amount)
	dialogue.add_text(str("[color=green](Gained ", amount, " nanites in data value) [/color]"))
	playSoundEffect("success.wav") #easier than putting it in every single rule?
	pass

func addHullStressWithFlair(amount: int):
	emit_signal("addPlayerHullStress", amount)
	dialogue.add_text(str("[color=red](Plus ", amount, "% hull stress) [/color]"))
	playSoundEffect("failure.wav")
	pass

func removeHullStressWithFlair(amount: int):
	emit_signal("removePlayerHullStress", amount)
	dialogue.add_text(str("[color=green](Minus ", amount, "% hull stress) [/color]"))
	playSoundEffect("success.wav")
	pass

func addMoraleWithFlair(amount: int):
	emit_signal("addPlayerMorale", amount)
	dialogue.add_text(str("[color=green](Plus ", amount, "% morale) [/color]"))
	playSoundEffect("success.wav")
	pass

func removeMoraleWithFlair(amount: int):
	emit_signal("removePlayerMorale", amount)
	dialogue.add_text(str("[color=red](Minus ", amount, "% morale) [/color]"))
	playSoundEffect("failure.wav")
	pass

func killCharacterWithFlair(written_occupation: String):
	var occupation = characterAPI.OCCUPATIONS.get(written_occupation)
	emit_signal("killCharacterWithOccupation", occupation)
	var character = player.get_character_with_occupation(occupation)
	dialogue.add_text(str("[color=red](", characterAPI.OCCUPATIONS.find_key(occupation).capitalize(), " ", character.get_display_name(), " is dead) [/color]"))
	playSoundEffect("failure.wav")
	pass

func setImage(path: String):
	dialogue.set_image(path)
	pass

func clearImage():
	dialogue.clear_image()

func playSoundEffect(path: String) -> void:
	dialogue.play_sound_effect(path)
	pass

func playMusic(path: String) -> void:
	dialogue.play_music(path)
	pass

func stopMusic() -> void:
	dialogue.stop_music()
	pass

func discoverRandomBodyWithFlair() -> void:
	var undiscovered_bodies: Array[bodyAPI] = []
	for body in system.bodies:
		if not (body.get_type() == starSystemAPI.BODY_TYPES.STAR or body.get_type() == starSystemAPI.BODY_TYPES.STATION):
			if not body.is_known():
				undiscovered_bodies.append(body)
	if undiscovered_bodies.size() > 0:
		var body: bodyAPI = undiscovered_bodies.pick_random()
		emit_signal("foundBody", body.get_identifier())
		dialogue.add_text(str("[color=green](Gained scan data for ", body.get_display_name(), ") [/color]"))
		playSoundEffect("success.wav") #easier than putting it in every single rule?
	else:
		dialogue.add_text(str("[color=green](Gained no new scan data) [/color]"))
	pass

func increaseSecurityOfficerStanding(_amount: int) -> void:
	player.increaseCharacterStanding(characterAPI.OCCUPATIONS.SECURITY_OFFICER, _amount)
	pass

func decreaseSecurityOfficerStanding(_amount: int) -> void:
	player.decreaseCharacterStanding(characterAPI.OCCUPATIONS.SECURITY_OFFICER, _amount)
	pass

func getPlanetDescriptionWithFlair(planet_type: String) -> void:
	var description: String = system.planet_descriptions.get(planet_type, String())
	dialogue.add_text("[color=darkgray]%s [/color]" % description)
	pass

func getStarDescriptionWithFlair(star_type: String) -> void:
	var description: String = system.star_descriptions.get(star_type, String())
	dialogue.add_text("[color=darkgray]%s [/color]" % description)
	pass

const reward_types = {
	"STRESS": {"LOW": 5, "MEDIUM": 15, "HIGH": 25},
	"VALUE": {"LOW": 2500, "MEDIUM": 5000, "HIGH": 25000},
	"DISCOVERY": {"LOW": 1, "MEDIUM": 2, "HIGH": 3}
}
func addRandomRewardWithFlair(rarity: String = "LOW") -> void:
	var reward = reward_types.keys().pick_random()
	match reward:
		"STRESS":
			removeHullStressWithFlair(reward_types.get(reward).get(rarity))
		"VALUE":
			addValueWithFlair(reward_types.get(reward).get(rarity))
		"DISCOVERY":
			for i in reward_types.get(reward).get(rarity) - 1:
				discoverRandomBodyWithFlair()
	pass

func unlockRandomUpgradeWithFlair() -> void:
	var IDs: Array[playerAPI.UPGRADE_ID] = []
	for ID in player.UPGRADE_ID:
		IDs.append(player.UPGRADE_ID.get(ID))
	
	var available_IDs = IDs.filter(is_available.bind(player.unlocked_upgrades))
	
	if available_IDs.size() > 0:
		var random_ID = available_IDs.pick_random()
		if player.is_upgrade_unlock_valid(random_ID):
			emit_signal("upgradeShip", random_ID, int())
			dialogue.add_text("[color=green](Unlocked %s) [/color]" % player.UPGRADE_ID.find_key(random_ID).capitalize())
			playSoundEffect("success.wav")
			return
	dialogue.add_text("[color=green](Unlocked no new module) [/color]")
	pass
func is_available(ID: int, _unlocked_upgrades: Array[playerAPI.UPGRADE_ID]) -> bool:
	if _unlocked_upgrades.find(ID) == -1:
		return true
	return false

func getNavBuoyOutcomeWithFlair(anomaly_seed: String) -> void: # for nav buoy space anomaly, have to input String anomaly_seed as fact reference substitution obviously doesnt convert to int, and thats fine
	emit_signal("rollNavBuoy", int(anomaly_seed)) #continued in _on_receive_nav_buoy_roll
	pass
func _on_receive_nav_buoy_roll(roll: Array) -> void:
	var nav_buoy_tag = roll.front()
	var nav_buoy_updated = roll.back()
	
	var base_message = "Analysts decode and log the faint pulses of data emanating from the buoy. The motherships transponder code is found to be [color=yellow]%s[/color]." % nav_buoy_tag
	
	match nav_buoy_updated:
		true:
			addValueWithFlair(2500)
			dialogue.add_text(base_message)
		false:
			addValueWithFlair(25000)
			dialogue.add_text("%s This transponder code is already present in on-board databanks; the extremely low probability of encountering the heritage of the same ship more than once so deep in space makes the data valuable for understanding the nature of wormhole travel." % base_message)
	pass



func categoryActive(wID: String) -> void:
	get_tree().call_group("objectivesManager", "mark_category", wID, objectiveAPI.STATES.NONE)
	pass

func categorySuccess(wID: String) -> void:
	get_tree().call_group("objectivesManager", "mark_category", wID, objectiveAPI.STATES.SUCCESS)
	pass

func categoryFailure(wID: String) -> void:
	get_tree().call_group("objectivesManager", "mark_category", wID, objectiveAPI.STATES.FAILURE)
	pass

func categoryClear(wID: String) -> void:
	get_tree().call_group("objectivesManager", "clear_category", wID)
	pass

func objectiveActive(wID: String) -> void:
	get_tree().call_group("objectivesManager", "mark_objective", wID, objectiveAPI.STATES.NONE)
	pass

func objectiveSuccess(wID: String) -> void:
	get_tree().call_group("objectivesManager", "mark_objective", wID, objectiveAPI.STATES.SUCCESS)
	pass

func objectiveFailure(wID: String) -> void:
	get_tree().call_group("objectivesManager", "mark_objective", wID, objectiveAPI.STATES.FAILURE)
	pass

func objectiveClear(wID: String) -> void:
	get_tree().call_group("objectivesManager", "clear_objective", wID)
	pass

func cycleAll(written_state: String) -> void: #dont use ts
	var change_state = objectiveAPI.STATES.get(written_state)
	get_tree().call_group("objectivesManager", "cycle_all", change_state)
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
