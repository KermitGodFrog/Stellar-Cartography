extends Node
var dialogue_memory: Dictionary

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



func speak(calling: Node, incoming_query: responseQuery, populate_data: bool = true):
	if populate_data:
		incoming_query.populateWithPlayerData(player)
		incoming_query.populateWithDialogueMemoryData(dialogue_memory)
	
	print("QUERY HANDLER: ", calling, " QUERYING ", incoming_query.facts)
	var ranked_rules: Dictionary = {}
	for rule in rules:
		var matches: int = 0
		for fact in incoming_query.facts:
			if rule.criteria.has(fact):
				if rule.criteria.get(fact) == incoming_query.facts.get(fact):
					matches += 1
				else: continue
			else: continue
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
	pass

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
					call(trigger_function)
			else:
				call(trigger_function)
	
	#trigger_rules: \\\\\\\\\\\\\
	for trigger_rule in rule.trigger_rules:
		if rules.has(trigger_rule):
			trigger_rule(calling, trigger_rule)
	dialogue.initialize(rule.text, rule.options)
	pass


func openDialog():
	dialogue.show()
	get_tree().paused = true
	pass

func closeDialog():
	dialogue.hide()
	get_tree().paused = false
	pass
