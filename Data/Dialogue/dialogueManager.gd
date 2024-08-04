extends Node

signal onCloseDialog(with_return_state)

var dialogue_memory: Dictionary #memory that is added by any query, and is always accessible indefinitely unless a timeout is specified
var tree_access_memory: Dictionary #memory that is explicitely added by a query via add_tree_access() - is added to any query until the dialog is closed
enum QUERY_TYPES {BEST, ALL}

#for populating query data
var player: playerAPI
var rules: Array[responseRule] = []
enum POINTERS {RULE, CRITERIA, APPLY_FACTS, TRIGGER_FUNCTIONS, TRIGGER_RULES, QUERY_ALL_CONCEPT, QUERY_BEST_CONCEPT, OPTIONS, TEXT}

@onready var dialogue = $dialogue/dialogue_control

func _ready():
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
					#DEPRECIATED, NOT ADDING
					pass
				"QUERY_ALL_CONCEPT":
					var array = convert_to_array(cell)
					if not array.is_empty():
						new_rule.query_all_concept = array
				"QUERY_BEST_CONCEPT":
					var array = convert_to_array(cell)
					if not array.is_empty():
						new_rule.query_best_concept = array
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
				
				#no support for >int or >float 
				
				new_dictionary[corrected_parts[i]] = type_corrected_value
				if corrected_parts.size() < (i + 2): break
				next_key += 2
		return new_dictionary
	else: return {}

func convert_to_array(cell : String) -> Array[String]:
	var parts = cell.split(",", false)
	var corrected_parts: Array[String] = []
	for part: String in parts: corrected_parts.append(part.dedent())
	
	if not corrected_parts.is_empty():
		return corrected_parts
	else: return []


func _physics_process(delta):
	for fact in dialogue_memory:
		var values = dialogue_memory.get(fact)
		var expiry_timer = values.back()
		
		if not expiry_timer == null:
			dialogue_memory[fact] = [values.front(), maxi(0, expiry_timer - delta)]
		
		if expiry_timer == 0:
			dialogue_memory.erase(fact)
	pass



func speak(calling: Node, incoming_query: responseQuery, populate_data: bool = true, type: QUERY_TYPES = QUERY_TYPES.BEST):
	if not incoming_query.tree_access_facts.is_empty():
		tree_access_memory.merge(incoming_query.tree_access_facts, true)
	
	if populate_data:
		incoming_query.populateWithPlayerData(player)
		incoming_query.populateWithDialogueMemoryData(dialogue_memory)
		incoming_query.populateWithTreeAccessMemoryData(tree_access_memory)
		incoming_query.populateWithWorldData()
	
	print("QUERY HANDLER: ", calling, " QUERYING ", incoming_query.facts)
	
	match type:
		QUERY_TYPES.BEST:
			
			var ranked_rules: Dictionary = {}
			for rule in rules:
				var matches: int = get_rule_matches(rule, incoming_query)
				ranked_rules[rule] = matches
			
			for rule in ranked_rules: #DEBUG!!!!!!!!!!!!!!!!!!!!!!!
				print_rich(str("[color=GREEN]", rule.get_name(), " : ", "[color=PINK]", ranked_rules.get(rule)))
			
			var sorted_values = ranked_rules.duplicate().values()
			sorted_values.sort() #counts upwards, e.g [0,0,1,1,1,2,2,5]
			var match_candidate_indexes: Array = []
			var max = sorted_values.max()
			for i in sorted_values.size(): if sorted_values[i] == max: match_candidate_indexes.append(i)
			
			var matched_index = match_candidate_indexes.pick_random()
			
			var matched_rule = ranked_rules.find_key(sorted_values[matched_index])
			if matched_rule: trigger_rule(calling, matched_rule)
			
		QUERY_TYPES.ALL: #FOR 'QUERY ALL CONCEPT'
			
			var matched_rules: Array[responseRule]
			for rule in rules:
				var matches: int = get_rule_matches(rule, incoming_query)
				if matches == rule.criteria.size():
					matched_rules.append(rule)
			
			for rule in matched_rules: #DEBUG!!!!!!!!!!!!!!!!!!!!!!!
				print_rich(str("[color=GREEN]", rule.get_name(), " : ", "[color=PINK]", "ALL"))
			
			for matched_rule in matched_rules:
				trigger_rule(calling, matched_rule)
			
	pass

func get_rule_matches(rule, incoming_query):
	var matches: int = 0
	for fact in incoming_query.facts:
		if rule.criteria.has(fact):
			if typeof(rule.criteria.get(fact)) == TYPE_STRING:
				match rule.criteria.get(fact).left(1):
					"<":
						var string_number = rule.criteria.get(fact).trim_prefix("<")
						var number = convert_string_number(string_number)
						
						if rule.criteria.get(fact) < number: #will this work>>???
							print(str(rule.criteria.get(fact), " ", number))
							matches += 1
						else: continue
					">":
						var string_number = rule.criteria.get(fact).trim_prefix(">")
						var number = convert_string_number(string_number)
						
						if rule.criteria.get(fact) > number:
							print(str(rule.criteria.get(fact), " ", number))
							matches += 1
						else: continue
					"<=":
						var string_number = rule.criteria.get(fact).trim_prefix("<=")
						var number = convert_string_number(string_number)
						
						if rule.criteria.get(fact) <= number:
							print(str(rule.criteria.get(fact), " ", number))
							matches += 1
						else: continue
					">=":
						var string_number = rule.criteria.get(fact).trim_prefix(">=")
						var number = convert_string_number(string_number)
						
						if rule.criteria.get(fact) >= number:
							print(str(rule.criteria.get(fact), " ", number))
							matches += 1
						else: continue
					_:
						if rule.criteria.get(fact) == incoming_query.facts.get(fact):
							print(str(rule.criteria.get(fact), " ", incoming_query.facts.get(fact)))
							matches += 1
						else: continue
			else:
				if rule.criteria.get(fact) == incoming_query.facts.get(fact):
					print(str(rule.criteria.get(fact), " ", incoming_query.facts.get(fact)))
					matches += 1
				else: continue
		else: continue
	return matches

func convert_string_number(string_number: String):
	if string_number.is_valid_int():
		return string_number.to_int()
	elif string_number.is_valid_float():
		return string_number.to_float()
	return string_number


func trigger_rule(calling: Node, rule: responseRule):
	print("QUERY HANDLER: ", calling, " TRIGGERING RULE ", rule.get_name())
	#apply_facts: \\\\\\\\\\\\\
	for fact in rule.apply_facts:
		dialogue_memory[fact] = rule.apply_facts.get(fact)
		print("QUERY HANDLER: ", calling, " APPLYING FACT ", fact)
	
	#trigger_functions: \\\\\\\\\\\\\
	for trigger_function in rule.trigger_functions:
		if has_method(trigger_function):
			var values = rule.trigger_functions.get(trigger_function)
			if values != null: 
				if typeof(values) == TYPE_ARRAY:
					print("QUERY HANDLER: ", calling, " TRIGGERING FUNCTION ", trigger_function)
					call(trigger_function, values)
				else:
					print("QUERY HANDLER: ", calling, " TRIGGERING FUNCTION ", trigger_function)
					call(trigger_function, values)
			else:
				call(trigger_function)
	
	#trigger_rules: \\\\\\\\\\\\\
	for trigger_rule in rule.trigger_rules:
		if rules.has(trigger_rule):
			trigger_rule(calling, trigger_rule)
	
	for concept in rule.query_all_concept:
		var new_query = responseQuery.new()
		new_query.add("concept", concept)
		speak(calling, new_query, true, QUERY_TYPES.ALL)
	
	for concept in rule.query_best_concept:
		var new_query = responseQuery.new()
		new_query.add("concept", concept)
		speak(calling, new_query, true, QUERY_TYPES.BEST)
	
	#text & options \\\\\\\\\\\\\
	if rule.text: dialogue.add_text(rule.text)
	if rule.options: dialogue.add_options(rule.options)
	pass


func openDialog():
	clearAll()
	dialogue.show()
	get_tree().paused = true
	pass

func closeDialog(with_return_state = null):
	tree_access_memory = {}
	dialogue.hide()
	get_tree().paused = false
	emit_signal("onCloseDialog", with_return_state)
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
