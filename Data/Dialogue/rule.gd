extends Resource
class_name responseRule

@export_category("Main")
@export var criteria: Dictionary

#if criteria is met, do these things
##Applies facts to the dialogue managers internal dialogue memory.
@export var apply_facts: Dictionary #applies facts to calling nodes internal list
##Triggers functions if present within the dialogue manager.
@export var trigger_functions: Dictionary #triggers functions if present in calling node
##Triggers specific rules while skipping the rule ranking process.
@export var trigger_rules: Array[String] #triggers additional rules without ranking process

#Like Starsector FireAll and FireBest 
@export_category("Query")
##Queries for a concept, and triggers all rules whose entire criteria is met.
@export var query_all_concept: Array[String]
##Queries for a concept, and triggers a rule whose entire criteria is met, and whose criteria is larger than all other rules whose entire criteria is met.
@export var query_best_concept: Array[String]
##Queries for a concept, and triggers a random rule from a group of rules whose entire criteria is met, and collectively have the highest number of criteria met.
@export var query_rand_best_concept: Array[String]
##Queries for a concept, and triggers a rule who has the most criteria met.
@export var query_old_best_concept: Array[String]

#just like the GDC - criteria, apply_facts and response (but response is two things like in starsector)

@export_category("Dialogue")
@export_multiline var text = ""
@export var options: Dictionary = {}


func is_configured() -> bool:
	if (not criteria.is_empty()) or (not apply_facts.is_empty()) or (not trigger_functions.is_empty()) or (not trigger_rules.is_empty()) or (not query_all_concept.is_empty()) or (not query_best_concept.is_empty()) or (not text.is_empty()) or (not options.is_empty()):
		return true
	else: return false
