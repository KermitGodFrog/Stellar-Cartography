extends AIUnitAPI
class_name exploringUnitAPI

enum TASKS {MOVE_TO_SURVEY, SURVEY, USE_LIDAR, MOVE_TO_WAIT, WAIT}
const task_schedule: Dictionary = {
	TASKS.MOVE_TO_SURVEY: [TASKS.SURVEY],
	TASKS.SURVEY: [TASKS.MOVE_TO_WAIT, TASKS.USE_LIDAR],
	TASKS.USE_LIDAR: [TASKS.MOVE_TO_SURVEY, TASKS.MOVE_TO_WAIT, TASKS.USE_LIDAR],
	TASKS.MOVE_TO_WAIT: [TASKS.WAIT],
	TASKS.WAIT: [TASKS.MOVE_TO_SURVEY, TASKS.MOVE_TO_WAIT, TASKS.USE_LIDAR]
}

@export_storage var current_task: TASKS

@export_storage var propensity_to_boost: float = 0.0 #has to be above 1.0 to boost

@export var valid_wait_target_ids: Array[int] = []
@export var valid_survey_target_ids: Array[int] = []
const MAX_VALID_PLANETS: int = 3
const MAX_VALID_WORMHOLES: int = 1

func _init() -> void:
	task_clock = clock.new()
	cooldown_clock = clock.new()
	pass

func initialize() -> void:
	generate_valid_targets()
	pass

func get_connection_pairs() -> Dictionary:
	var connections: Dictionary = {
		cooldown_clock.time_expired: _on_cooldown_clock_time_expired,
		boosting_changed: _on_boosting_changed
	}
	return connections

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
		TASKS.MOVE_TO_SURVEY, TASKS.MOVE_TO_WAIT:
			propensity_to_boost += global_data.get_randf(0.0,1.0) * 10.0 * delta
		TASKS.SURVEY, TASKS.USE_LIDAR, TASKS.WAIT:
			propensity_to_boost = 0.0
	
	propensity_to_boost = maxf(0, propensity_to_boost - global_data.get_randf(0.0,1.0) * 10.0 * delta)
	
	if propensity_to_boost >= 1.0:
		boosting = true
	else:
		boosting = false
	pass

func check_task_status() -> TASK_STATUSES:
	match current_task:
		TASKS.MOVE_TO_SURVEY, TASKS.MOVE_TO_WAIT:
			if target != null:
				if is_action_pending():
					if pending_action_body == target:
						return TASK_STATUSES.ONGOING
				elif not is_action_pending():
					if action_body == target:
						return TASK_STATUSES.COMPLETE
			return TASK_STATUSES.FAILED
		TASKS.SURVEY, TASKS.WAIT:
			if target != null:
				if not is_action_pending():
					if action_body == target:
						if task_clock.is_stopped():
							return TASK_STATUSES.COMPLETE
						else:
							return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.USE_LIDAR:
			if get_current_action_type() == ACTION_TYPES.NONE:
				if task_clock.is_stopped():
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
	
	return TASK_STATUSES.FAILED

func switch_task(override_task = null) -> void:
	var new_task: TASKS = TASKS.values()[0]
	if override_task != null:
		new_task = override_task
	else:
		var options: Array = task_schedule.get(current_task)
		new_task = options.pick_random()
	
	match new_task:
		TASKS.MOVE_TO_SURVEY:
			target = null
			if valid_survey_target_ids.size() > 0:
				var new_target_id = valid_survey_target_ids.pick_random()
				var new_target = system.get_body_from_identifier(new_target_id)
				target = new_target
				orbit_body(target)
		TASKS.SURVEY:
			task_clock.start(global_data.get_randf(10.0,30.0))
		TASKS.USE_LIDAR:
			task_clock.start(15.0)
			emit_signal("play_sound", "res://sound/game/bodyAPIs/unitAPIs/LIDAR_unit_suite.tres", -12.0, "SFX")
			course_to_position(position)
		TASKS.MOVE_TO_WAIT:
			target = null
			if valid_wait_target_ids.size() > 0:
				var new_target_id = valid_wait_target_ids.pick_random()
				var new_target = system.get_body_from_identifier(new_target_id)
				target = new_target
				orbit_body(target)
		TASKS.WAIT:
			task_clock.start(global_data.get_randf(30.0,90.0))
	
	print("UNIT (%s): NEW TASK -> %s" % [self, TASKS.find_key(new_task)])
	
	start_cooldown()
	current_task = new_task
	propensity_to_boost = 0.0
	#metadata["_current_task"] = TASKS.find_key(current_task)
	pass

#MISC FUNCTIONS
func generate_valid_targets() -> void:
	valid_wait_target_ids.clear()
	valid_survey_target_ids.clear()
	
	var planets = system.get_planets()
	var wormholes = system.get_wormholes()
	
	
	for i in range(MAX_VALID_PLANETS):
		if planets.size() > 0:
			var planet = planets.pick_random()
			valid_wait_target_ids.append(planet.get_identifier())
			valid_survey_target_ids.append(planet.get_identifier())
			planets.erase(planet)
	
	for i in range(MAX_VALID_WORMHOLES):
		if wormholes.size() > 0:
			var wormhole = wormholes.pick_random()
			valid_wait_target_ids.append(wormhole.get_identifier())
			wormholes.erase(wormhole)
	
	valid_wait_target_ids.append(system.get_first_star().get_identifier())
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
