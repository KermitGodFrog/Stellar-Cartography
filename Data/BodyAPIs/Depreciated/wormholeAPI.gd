extends bodyAPI
class_name wormholeAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

@export var destination_system: starSystemAPI
@export var post_jumps_remaining: int = 0
@export var is_disabled: bool = false

func is_wormhole(): #has to be wormhole lol. overrides bodyAPI class
	return true
