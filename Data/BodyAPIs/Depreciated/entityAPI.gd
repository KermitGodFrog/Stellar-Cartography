extends bodyAPI
class_name entityAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

@export var entity_classification: int #game data
@export var captures_remaining: int = 3
var stored_generation_positions: PackedVector3Array = []
var stored_generation_basis: Basis

func is_entity():
	return true

func remove_captures_remaining(amount: int):
	captures_remaining = maxi(0, captures_remaining - amount)
	pass
