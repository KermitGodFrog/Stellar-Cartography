extends Node

signal onCloseDialog(with_return_state)

var dialogue_memory: Dictionary
enum QUERY_TYPES {BEST, ALL}

#for populating query data
var player: playerAPI

var rules: Array[responseRule] = []

@onready var dialogue = $dialogue/dialogue_control

func _ready():
	var rule_path = global_data.get_all_files("res://Data/Dialogue/Rules", "tres")
	for r in rule_path:
		rules.append(load(r))
	pass

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
	if populate_data:
		incoming_query.populateWithPlayerData(player)
		incoming_query.populateWithDialogueMemoryData(dialogue_memory)
	
	print("QUERY HANDLER: ", calling, " QUERYING ", incoming_query.facts)
	
	match type:
		QUERY_TYPES.BEST:
			
			var ranked_rules: Dictionary = {}
			for rule in rules:
				var matches: int = get_rule_matches(rule, incoming_query)
				ranked_rules[rule] = matches
			
			for rule in ranked_rules: #DEBUG!!!!!!!!!!!!!!!!!!!!!!!
				print(str(rule.resource_path, " : ", ranked_rules.get(rule)))
			
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
						var number = rule.criteria.get(fact).trim_prefix("<")
						if float(rule.criteria.get(fact)) < float(number): #will this work>>???
							matches += 1
						else: continue
					">":
						var number = rule.criteria.get(fact).trim_prefix(">")
						if float(rule.criteria.get(fact)) > float(number):
							matches += 1
						else: continue
					_:
						if rule.criteria.get(fact) == incoming_query.facts.get(fact):
							matches += 1
						else: continue
			else:
				if rule.criteria.get(fact) == incoming_query.facts.get(fact):
					matches += 1
				else: continue
		else: continue
	return matches

func trigger_rule(calling: Node, rule: responseRule):
	print("QUERY HANDLER: ", calling, " TRIGGERING RULE ", global_data.get_resource_name(rule))
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
	reset()
	dialogue.show()
	get_tree().paused = true
	pass

func closeDialog(with_return_state = null):
	dialogue.hide()
	get_tree().paused = false
	emit_signal("onCloseDialog", with_return_state)
	pass

func resetText():
	dialogue.reset_text()
	pass

func resetOptions():
	dialogue.reset_options()
	pass

func reset():
	dialogue.reset()
	pass
