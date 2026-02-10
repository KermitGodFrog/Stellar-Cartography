extends AIUnitAPI
class_name neutralUnitAPI

enum TASKS {MOVE, SURVEY}
enum TASK_STATUSES {ONGOING, COMPLETE, FAILED}
const TASK_SCHEDULE: Dictionary = {TASKS.MOVE: [TASKS.SURVEY], TASKS.SURVEY: [TASKS.MOVE]}
@export_storage var current_task: TASKS
var task_switching_enabled: bool = true

@export_storage var target_planet : planetBodyAPI

func initialize() -> void:
	cooldown_clock.time_expired.connect(_on_cooldown_clock_time_expired)
	pass

func advance(delta) -> void:
	task_clock.tick(delta)
	cooldown_clock.tick(delta)
	var status = check_task_status()
	if status == TASK_STATUSES.COMPLETE or status == TASK_STATUSES.FAILED:
		switch_task()
	pass

func check_task_status() -> TASK_STATUSES:
	match current_task:
		TASKS.MOVE:
			if is_action_pending():
				if pending_action_body == target_planet:
					return TASK_STATUSES.ONGOING
			elif not is_action_pending():
				if action_body == target_planet:
					return TASK_STATUSES.COMPLETE
			return TASK_STATUSES.FAILED
		TASKS.SURVEY:
			if not is_action_pending():
				if action_body == target_planet:
					if task_clock.is_stopped():
						return TASK_STATUSES.COMPLETE
					else:
						return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
	
	return TASK_STATUSES.FAILED

func switch_task() -> void:
	var options: Array = TASK_SCHEDULE.get(current_task)
	var new_task = options.pick_random()
	current_task = new_task
	
	match new_task:
		TASKS.MOVE:
			var planets = system.get_bodies_of_body_type(starSystemAPI.BODY_TYPES.PLANET)
			target_planet = planets.pick_random()
			orbit_body(target_planet)
		TASKS.SURVEY:
			task_clock.start(10.0)
	
	task_switching_enabled = false
	cooldown_clock.start(2.5)
	current_task = new_task
	pass

func _on_cooldown_clock_time_expired() -> void:
	task_switching_enabled = true
	pass
