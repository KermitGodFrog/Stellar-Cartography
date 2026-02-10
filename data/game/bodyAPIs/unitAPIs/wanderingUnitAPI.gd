extends AIUnitAPI
class_name wanderingUnitAPI

enum TASKS {MOVE_TO_SURVEY, SURVEY, MOVE_TO_DOCK, DOCK}
const task_schedule: Dictionary = {
	TASKS.MOVE_TO_SURVEY: [TASKS.SURVEY], 
	TASKS.SURVEY: [TASKS.MOVE_TO_SURVEY, TASKS.MOVE_TO_SURVEY, TASKS.MOVE_TO_DOCK], 
	TASKS.MOVE_TO_DOCK: [TASKS.DOCK],
	TASKS.DOCK: [TASKS.MOVE_TO_SURVEY]
}
@export_storage var current_task: TASKS
var task_switching_enabled: bool = true

@export_storage var target : orbitBodyAPI

@export_storage var propensity_to_boost: float = 0.0 #has to be above 1.0 to boost

func initialize() -> void:
	task_clock = clock.new()
	cooldown_clock = clock.new()
	cooldown_clock.time_expired.connect(_on_cooldown_clock_time_expired)
	boosting_changed.connect(_on_boosting_changed)
	pass

func advance(delta) -> void:
	task_clock.tick(delta)
	cooldown_clock.tick(delta)
	
	update_boosting_status(delta)
	
	var status = check_task_status()
	if cooldown_clock.is_stopped():
		if status in [TASK_STATUSES.COMPLETE, TASK_STATUSES.FAILED]:
			print("UNIT (%s): TASK %s -> %s" % [self, TASKS.find_key(current_task), TASK_STATUSES.find_key(status)])
			switch_task()
	pass

func update_boosting_status(delta) -> void:
	match current_task:
		TASKS.MOVE_TO_SURVEY, TASKS.MOVE_TO_DOCK:
			propensity_to_boost += global_data.get_randf(0.0,1.0) * 10.0 * delta
		TASKS.SURVEY, TASKS.DOCK:
			propensity_to_boost = 0.0
	
	propensity_to_boost = maxf(0, propensity_to_boost - global_data.get_randf(0.0,1.0) * 10.0 * delta)
	
	if propensity_to_boost >= 1.0:
		boosting = true
	else:
		boosting = false
	pass


func check_task_status() -> TASK_STATUSES:
	match current_task:
		TASKS.MOVE_TO_SURVEY, TASKS.MOVE_TO_DOCK:
			if target != null:
				if is_action_pending():
					if pending_action_body == target:
						return TASK_STATUSES.ONGOING
				elif not is_action_pending():
					if action_body == target:
						return TASK_STATUSES.COMPLETE
				return TASK_STATUSES.FAILED
		TASKS.SURVEY, TASKS.DOCK:
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
		TASKS.MOVE_TO_SURVEY:
			var planets = system.get_bodies_of_body_type(starSystemAPI.BODY_TYPES.PLANET)
			target = planets.pick_random()
			orbit_body(target)
		TASKS.SURVEY:
			task_clock.start(global_data.get_randf(10.0,30.0))
		TASKS.MOVE_TO_DOCK:
			var stations = system.get_bodies_of_body_type(starSystemAPI.BODY_TYPES.STATION)
			if stations.size() > 0:
				target = stations.pick_random()
				follow_body(target)
		TASKS.DOCK:
			task_clock.start(global_data.get_randf(5.0,10.0))
	
	start_cooldown()
	current_task = new_task
	pass

func start_cooldown() -> void:
	task_switching_enabled = false
	cooldown_clock.start(2.5)
	pass



func _on_cooldown_clock_time_expired() -> void:
	task_switching_enabled = true
	pass

func _on_boosting_changed(new_value: bool):
	match new_value:
		true:
			propensity_to_boost += 0.5
		false:
			propensity_to_boost = 0.0
	pass
