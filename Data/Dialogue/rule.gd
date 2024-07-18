extends Resource
class_name responseRule

@export var criteria: Dictionary

#if criteria is met, do these things
@export var apply_facts: Dictionary #applies facts to calling nodes internal list
@export var trigger_functions: Dictionary #triggers functions if present in calling node
@export var trigger_rules: Array[responseRule] #triggers additional rules without ranking process

#just like the GDC - criteria, apply_facts and response (but response is two things like in starsector)
