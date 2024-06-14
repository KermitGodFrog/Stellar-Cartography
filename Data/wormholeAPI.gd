extends bodyAPI
class_name wormholeAPI

var destination_system: starSystemAPI
var post_jumps_remaining: int = 0
var is_disabled: bool = false

func is_wormhole(): #has to be wormhole lol. overrides bodyAPI class
	return true
