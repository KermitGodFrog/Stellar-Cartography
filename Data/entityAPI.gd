extends bodyAPI
class_name entityAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

@export var entity_classification: int #game data

func is_entity():
	return true
