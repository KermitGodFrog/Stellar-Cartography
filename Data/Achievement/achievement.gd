extends Resource
class_name achievement
#FILE naming syntax: concept (if applicable, else 'any'), short phrase describing other dialogue criteria. Written in camel case, verbose numbers. The word 'player' shall not be used outside of the concept name.

@export var name : String = ""
##Description syntax: short phrase for flair (if applicable), short phrase describing all of the criteria necessary to be unlocked.
@export_multiline var description = ""
@export var dialogue_criteria: Dictionary = {}
