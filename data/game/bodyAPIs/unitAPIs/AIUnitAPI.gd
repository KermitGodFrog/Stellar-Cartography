extends unitBodyAPI
class_name AIUnitAPI

enum TASK_STATUSES {ONGOING, COMPLETE, FAILED}
var task_switching_enabled: bool = true

@export_storage var task_clock: clock
@export_storage var cooldown_clock: clock
@export_storage var stun_clock: clock

@export_storage var current_task: int #TASKS

@export_storage var target_id: int
var target: bodyAPI:
	set(value):
		if value != null:
			target_id = value.get_identifier()
		target = value
	get():
		if target != null:
			return target
		elif target_id != 0:
			var reclaim_target = system.get_body_from_identifier(target_id)
			target = reclaim_target
			return target
		else:
			return null

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
	elif player != null:
		push_warning("WARNING: UNIT %s USING PLAYER CURRENT STAR SYSTEM AS SYSTEM IS NOT SET" % self)
		return player.current_star_system
	else:
		return null
func set_system(value) -> void:
	system = value
	pass

func get_player() -> playerAPI:
	return player
func set_player(value) -> void:
	player = value

#misc functions!

func stun(_duration: float = 1.0) -> void: #this is called by system_map async_add_unit_ping directly
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

func get_adjusted_speed() -> int:
	if stunned:
		return 1
	if boosting:
		return speed * 5 * (1 + (-int(in_asteroid_belt) * 0.5))
	else:
		return speed * (1 + (-int(in_asteroid_belt) * 0.5))



# other misc stuff (23/9/26)

func get_tasks() -> Dictionary:
	return Dictionary()

func get_task_schedule() -> Dictionary:
	return Dictionary()



func _init() -> void:
	task_clock = clock.new()
	cooldown_clock = clock.new()
	stun_clock = clock.new()
	pass

func advance(delta) -> void:
	task_clock.tick(delta)
	cooldown_clock.tick(delta)
	stun_clock.tick(delta)
	
	var status := check_task_status()
	if cooldown_clock.is_stopped():
		if status in [TASK_STATUSES.COMPLETE, TASK_STATUSES.FAILED]:
			print("UNIT (%s): TASK %s -> %s" % [self, get_tasks().find_key(current_task), TASK_STATUSES.find_key(status)])
			switch_task()
	pass

func check_task_status() -> TASK_STATUSES:
	return TASK_STATUSES.FAILED

func switch_task(override_task = null) -> int:
	var new_task: int = get_tasks().values()[0]
	if override_task != null:
		new_task = override_task
	else:
		var options: Array = get_task_schedule().get(current_task)
		new_task = options.pick_random()
	
	print("UNIT (%s): NEW TASK -> %s" % [self, get_tasks().find_key(new_task)])
	
	start_cooldown()
	current_task = new_task
	return new_task

func start_cooldown() -> void:
	task_switching_enabled = false
	cooldown_clock.start(2.5)
	pass

func _on_cooldown_clock_time_expired() -> void:
	task_switching_enabled = true
	pass

func get_connection_pairs() -> Dictionary:
	var connections: Dictionary = {
		cooldown_clock.time_expired: _on_cooldown_clock_time_expired,
	}
	return connections
