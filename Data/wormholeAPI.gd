extends bodyAPI
class_name wormholeAPI

var destination_system: starSystemAPI
@export var post_jumps_remaining: int = 0

func is_wormhole(): #has to be wormhole lol. overrides bodyAPI class
	return true
