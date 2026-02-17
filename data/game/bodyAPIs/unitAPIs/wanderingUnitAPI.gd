extends AIUnitAPI
class_name wanderingUnitAPI

enum TASKS {MOVE_TO_WAIT, WAIT, MOVE_TO_DOCK, DOCK}
const task_schedule: Dictionary = {
	TASKS.MOVE_TO_WAIT: [TASKS.WAIT], 
	TASKS.WAIT: [TASKS.MOVE_TO_WAIT, TASKS.MOVE_TO_WAIT, TASKS.MOVE_TO_DOCK], 
	TASKS.MOVE_TO_DOCK: [TASKS.DOCK],
	TASKS.DOCK: [TASKS.MOVE_TO_WAIT]
}
@export_storage var current_task: TASKS

@export_storage var propensity_to_boost: float = 0.0 #has to be above 1.0 to boost

@export var valid_wait_target_ids: Array[int] = []
@export var valid_dock_target_ids: Array[int] = []
const MAX_VALID_PLANETS: int = 2
const MAX_VALID_WORMHOLES: int = 1

func _init() -> void:
	task_clock = clock.new()
	cooldown_clock = clock.new()
	pass

func initialize() -> void:
	cooldown_clock.time_expired.connect(_on_cooldown_clock_time_expired)
	boosting_changed.connect(_on_boosting_changed)
	generate_valid_targets()
	pass

func advance(delta) -> void:
	task_clock.tick(delta)
	cooldown_clock.tick(delta)
	
	calculate_asteroid_belt_slowdown()
	update_boosting_status(delta)
	
	var status = check_task_status()
	if cooldown_clock.is_stopped():
		if status in [TASK_STATUSES.COMPLETE, TASK_STATUSES.FAILED]:
			print("UNIT (%s): TASK %s -> %s" % [self, TASKS.find_key(current_task), TASK_STATUSES.find_key(status)])
			switch_task()
	pass

func update_boosting_status(delta) -> void:
	match current_task:
		TASKS.MOVE_TO_WAIT, TASKS.MOVE_TO_DOCK:
			propensity_to_boost += global_data.get_randf(0.0,1.0) * 10.0 * delta
		TASKS.WAIT, TASKS.DOCK:
			propensity_to_boost = 0.0
	
	propensity_to_boost = maxf(0, propensity_to_boost - global_data.get_randf(0.0,1.0) * 10.0 * delta)
	
	if propensity_to_boost >= 1.0:
		boosting = true
	else:
		boosting = false
	pass

func check_task_status() -> TASK_STATUSES:
	match current_task:
		TASKS.MOVE_TO_WAIT, TASKS.MOVE_TO_DOCK:
			if target != null:
				if is_action_pending():
					if pending_action_body == target:
						return TASK_STATUSES.ONGOING
				elif not is_action_pending():
					if action_body == target:
						return TASK_STATUSES.COMPLETE
			return TASK_STATUSES.FAILED
		TASKS.WAIT, TASKS.DOCK:
			if target != null:
				if not is_action_pending():
					if action_body == target:
						if task_clock.is_stopped():
							return TASK_STATUSES.COMPLETE
						else:
							return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
	
	return TASK_STATUSES.FAILED

func switch_task() -> void:
	var options: Array = task_schedule.get(current_task)
	var new_task = options.pick_random()
	
	match new_task:
		TASKS.MOVE_TO_WAIT:
			target = null
			if valid_wait_target_ids.size() > 0:
				var new_target_id = valid_wait_target_ids.pick_random()
				var new_target = system.get_body_from_identifier(new_target_id)
				target = new_target
				orbit_body(target)
		TASKS.WAIT:
			task_clock.start(global_data.get_randf(30.0,300.0))
		TASKS.MOVE_TO_DOCK:
			target = null
			if valid_dock_target_ids.size() > 0:
				var new_target_id = valid_dock_target_ids.pick_random()
				var new_target = system.get_body_from_identifier(new_target_id)
				target = new_target
				go_to_body(target)
		TASKS.DOCK:
			task_clock.start(global_data.get_randf(5.0,10.0))
	
	print("UNIT (%s): NEW TASK -> %s" % [self, TASKS.find_key(new_task)])
	
	start_cooldown()
	current_task = new_task
	propensity_to_boost = 0.0
	metadata["_current_task"] = TASKS.find_key(current_task)
	pass

#MISC FUNCTIONS
func generate_valid_targets() -> void:
	valid_wait_target_ids.clear()
	valid_dock_target_ids.clear()
	
	var planets = system.get_planets()
	var wormholes = system.get_wormholes()
	
	for i in range(MAX_VALID_PLANETS):
		var planet = planets.pick_random()
		valid_wait_target_ids.append(planet.get_identifier())
		planets.erase(planet)
	
	for i in range(MAX_VALID_WORMHOLES):
		var wormhole = wormholes.pick_random()
		valid_wait_target_ids.append(wormhole.get_identifier())
		wormholes.erase(wormhole)
	
	valid_wait_target_ids.append(system.get_first_star().get_identifier())
	
	for station in system.get_stations():
		valid_dock_target_ids.append(station.get_identifier())
		valid_wait_target_ids.append(station.get_identifier())
	pass



#region cooldown stuff
func start_cooldown() -> void:
	task_switching_enabled = false
	cooldown_clock.start(2.5)
	pass

func _on_cooldown_clock_time_expired() -> void:
	task_switching_enabled = true
	pass
#endregion

func _on_boosting_changed(new_value: bool):
	match new_value:
		true:
			propensity_to_boost += 0.5
		false:
			propensity_to_boost = 0.0
	pass
