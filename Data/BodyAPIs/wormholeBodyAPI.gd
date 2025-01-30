extends circularBodyAPI
class_name wormholeBodyAPI
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

@export var destination_system: starSystemAPI
@export_storage var post_jumps_remaining: int = 0
@export var disabled: bool = false

func is_disabled() -> bool:
	return disabled
