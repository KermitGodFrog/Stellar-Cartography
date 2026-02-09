extends unitBodyAPI
class_name neutralUnitBodyAPI

enum TASKS {MOVE, SURVEY}
var current_task: TASKS
var task_clock: Timer

func initialize() -> void:
	task_clock = Timer.new() 
	task_clock.set_one_shot(true)
	pass

func advance(_delta) -> void:
	var task_complete = is_task_complete()
	if task_complete:
		current_task = pick_new_task()
	pass

func is_task_complete() -> bool:
	match current_task:
		_ when current_task == null:
			return true
		TASKS.MOVE:
			if action_body:
				return true
		TASKS.SURVEY:
			if task_clock.is_stopped():
				return true
	
	return false

func pick_new_task() -> TASKS:
	var new_task = TASKS.values().pick_random()
	match new_task:
		TASKS.MOVE:
			
			
			
			
			pass
			
			
			
			
		TASKS.SURVEY:
			task_clock.start(10.0)
	return new_task
