extends AIUnitAPI

enum TASKS {RELOCATE, WAIT}
const task_schedule: Dictionary = {
	TASKS.RELOCATE: [TASKS.WAIT, TASKS.RELOCATE],
	TASKS.WAIT: [TASKS.RELOCATE]
}

@export_storage var current_task: TASKS

@export_storage var last_player_position: Vector2
@export_storage var relocation_offset: Vector2

func _init() -> void:
	task_clock = clock.new()
	cooldown_clock = clock.new()
	pass

func get_connection_pairs() -> Dictionary:
	var connections: Dictionary = {
		cooldown_clock.time_expired: _on_cooldown_clock_time_expired,
	}
	return connections

func advance(delta) -> void:
	task_clock.tick(delta)
	cooldown_clock.tick(delta)
	
	match current_task:
		TASKS.RELOCATE:
			var player_displacement = player.position - last_player_position
			var player_velocity = player_displacement / delta
			target_position = player.position + (player_velocity * 30.0) + relocation_offset
	
	var status = check_task_status()
	if cooldown_clock.is_stopped():
		if status in [TASK_STATUSES.COMPLETE, TASK_STATUSES.FAILED]:
			print("UNIT (%s): TASK %s -> %s" % [self, TASKS.find_key(current_task), TASK_STATUSES.find_key(status)])
			switch_task()
	
	last_player_position = player.position
	pass

func check_task_status() -> TASK_STATUSES:
	match current_task:
		TASKS.RELOCATE:
			if get_current_action_type() == ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
				if position.distance_to(target_position) < (player.radius + 1.0):
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.WAIT:
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
		TASKS.RELOCATE:
			set_action_type(ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE, null) #continuously updated in advance function
			var dir = Vector2.UP.rotated(deg_to_rad(global_data.get_randi(0, 360)))
			relocation_offset = dir * global_data.get_randf(10, 150)
		TASKS.WAIT:
			task_clock.start(30.0)
			course_to_position(position)
	
	print("UNIT (%s): NEW TASK -> %s" % [self, TASKS.find_key(new_task)])
	
	start_cooldown()
	current_task = new_task
	#metadata["_current_task"] = TASKS.find_key(current_task)
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
