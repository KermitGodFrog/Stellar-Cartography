extends unitBodyAPI
class_name AIUnitAPI

enum TASK_STATUSES {ONGOING, COMPLETE, FAILED}
var task_switching_enabled: bool = true

@export_storage var task_clock: clock
@export_storage var cooldown_clock: clock
@export_storage var stun_clock: clock

@export_storage var target : orbitBodyAPI

@export_storage var stunned: bool = false:
	get = is_stunned, set = set_stunned

var system: starSystemAPI: #updated in TWO ways: 1) set by starSystemAPI while creating the body, 2) set by game.gd on _ready when in the CONTINUE query type
	get = get_system, set = set_system
var player: playerAPI: #updated in TWO ways: 1) updated by game.gd on _on_switch_star_system, 2) set by game.gd on _ready when in the CONTINUE query type
	get = get_player, set = set_player

func is_stunned() -> bool:
	return stunned
func set_stunned(value) -> void:
	stunned = value
	pass

func get_system() -> starSystemAPI:
	if system != null:
		return system
	else:
		print_debug("UNIT (%s): USING PLAYER CURRENT STAR SYSTEM AS SYSTEM IS NOT SET" % self)
		return player.current_star_system
func set_system(value) -> void:
	system = value
	pass

func get_player() -> playerAPI:
	return player
func set_player(value) -> void:
	player = value

func check_task_status() -> TASK_STATUSES:
	return TASK_STATUSES.FAILED
func switch_task() -> void: #func switch_task(override: TASKS = null) -> void:
	pass



#misc functions!

func stun() -> void: #this is called by system_map async_add_unit_ping directly
	pass

func calculate_asteroid_belt_slowdown() -> void:
	var i: int = 0
	var asteroid_belts = system.get_bodies_of_body_type(starSystemAPI.BODY_TYPES.ASTEROID_BELT)
	if asteroid_belts:
		for belt in asteroid_belts:
			var lower_echelon = belt.orbit_distance - belt.metadata.get("belt_width") / 2
			var upper_echelon = belt.orbit_distance + belt.metadata.get("belt_width") / 2
			var distance = position.distance_to(belt.position)
			if distance > lower_echelon and distance < upper_echelon:
				i += 1
				break
	if i == 0:
		in_asteroid_belt = false
	elif i > 0:
		in_asteroid_belt = true
	pass

func is_hostile() -> bool:
	if metadata.get("hostile", false) == true:
		return true
	return false

func get_adjusted_speed() -> int:
	if stunned:
		return 1
	if boosting:
		return speed * 5 * (1 + (-int(in_asteroid_belt) * 0.5))
	else:
		return speed * (1 + (-int(in_asteroid_belt) * 0.5))
