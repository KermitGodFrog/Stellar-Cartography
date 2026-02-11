extends AIUnitAPI
class_name interceptingUnitAPI

enum TASKS {MOVE_TO_SURVEY, SURVEY, USE_LIDAR, MOVE_TO_LIDAR, INVESTIGATE_LIDAR, MOVE_TO_INTERCEPT, INTERCEPT, MOVE_TO_RE_DISCOVER}
const task_schedule: Dictionary = {
	TASKS.MOVE_TO_SURVEY: [TASKS.SURVEY],
	TASKS.SURVEY: [TASKS.MOVE_TO_SURVEY, TASKS.USE_LIDAR],
	TASKS.USE_LIDAR: [TASKS.MOVE_TO_SURVEY], #maybe make this play a sound?? not sureeee...
	TASKS.MOVE_TO_LIDAR: [TASKS.INVESTIGATE_LIDAR], #overrides if 'USE_LIDAR' by chance finds the player 
	TASKS.INVESTIGATE_LIDAR: [TASKS.MOVE_TO_SURVEY, TASKS.USE_LIDAR],
	TASKS.MOVE_TO_INTERCEPT: [TASKS.INTERCEPT], #overrides if ENTERING the players scanner profile
	TASKS.INTERCEPT: [TASKS.MOVE_TO_INTERCEPT],
	TASKS.MOVE_TO_RE_DISCOVER: [TASKS.MOVE_TO_SURVEY, TASKS.USE_LIDAR] #overrides if EXITING the players scanner profile. follows the players dir vector for 1 minute and then ceases
}
@export_storage var current_task: TASKS

@export_storage var last_player_position: Vector2 = Vector2.ZERO
@export_storage var within_player_profile: bool = false:
	set(value):
		if within_player_profile != value:
			match value:
				true:
					_on_entered_player_scanner_profile()
				false:
					_on_exited_player_scanner_profile()
		within_player_profile = value

const MAX_SONAR_LENGTH := 300.0 #currently what it is in sonar_interface, but if i ever change it...

func initialize() -> void:
	task_clock = clock.new()
	cooldown_clock = clock.new()
	cooldown_clock.time_expired.connect(_on_cooldown_clock_time_expired)
	pass

func advance(delta) -> void:
	task_clock.tick(delta)
	cooldown_clock.tick(delta)
	
	update_scanner_status()
	
	match current_task:
		TASKS.MOVE_TO_INTERCEPT:
			target_position = player.position
	
	var status = check_task_status()
	if cooldown_clock.is_stopped():
		if status in [TASK_STATUSES.COMPLETE, TASK_STATUSES.FAILED]:
			print("UNIT (%s): TASK %s -> %s" % [self, TASKS.find_key(current_task), TASK_STATUSES.find_key(status)])
			switch_task()
	pass

func update_scanner_status() -> void:
	var contacts = system.get_units_in_scanner_range(player.position, player.scanner_profile)
	within_player_profile = contacts.has(self)
	pass

func check_task_status() -> TASK_STATUSES:
	match current_task:
		TASKS.MOVE_TO_SURVEY:
			if target != null:
				if is_action_pending():
					if pending_action_body == target:
						return TASK_STATUSES.ONGOING
				elif not is_action_pending():
					if action_body == target:
						return TASK_STATUSES.COMPLETE
				return TASK_STATUSES.FAILED
		TASKS.SURVEY:
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
					if sonar_theorised_player():
						switch_task(TASKS.MOVE_TO_LIDAR)
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.INVESTIGATE_LIDAR, TASKS.MOVE_TO_RE_DISCOVER, TASKS.INTERCEPT:
			if get_current_action_type() == ACTION_TYPES.NONE:
				if task_clock.is_stopped():
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.MOVE_TO_LIDAR, TASKS.MOVE_TO_INTERCEPT:
			if get_current_action_type() == ACTION_TYPES.NONE:
				if position.distance_to(target_position) < system.get_default_radius_solar_radii(): #assumes that the players radius is the default
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
			var planets = system.get_bodies_of_body_type(starSystemAPI.BODY_TYPES.PLANET)
			target = planets.pick_random()
			orbit_body(target)
		TASKS.SURVEY:
			task_clock.start(global_data.get_randf(10.0,30.0))
		TASKS.USE_LIDAR:
			task_clock.start(15.0)
			course_to_position(position)
		TASKS.MOVE_TO_LIDAR:
			if last_player_position != Vector2.ZERO:
				course_to_position(last_player_position)
		TASKS.INVESTIGATE_LIDAR:
			task_clock.start(global_data.get_randf(5.0, 7.5))
			course_to_position(position)
		TASKS.MOVE_TO_INTERCEPT:
			set_action_type(ACTION_TYPES.NONE, null) #continuously updated in advance function
			pass
		TASKS.INTERCEPT:
			print("INTERCEPTED! FOLLOWING BODY SIGNAL SENT")
			emit_signal("followingBody", player)
			task_clock.start(3.0) #(physical) cooldown time before it can move to intercept again
		TASKS.MOVE_TO_RE_DISCOVER:
			task_clock.start(global_data.get_randf(20.0,40.0))
			var dir = position.direction_to(last_player_position)
			var course = position + (dir * 1000.0)
			course_to_position(course)
	
	print("UNIT (%s): NEW TASK -> %s" % [self, TASKS.find_key(new_task)])
	
	start_cooldown()
	current_task = new_task
	pass

func sonar_theorised_player() -> bool:
	if position.distance_to(player.position) < MAX_SONAR_LENGTH:
		var theorised_player = randf() > 0.5 #make this smarter later - taking distance and stuff into account
		if theorised_player:
			last_player_position = player.position
		return theorised_player
	return false







#region cooldown stuff
func start_cooldown() -> void:
	task_switching_enabled = false
	cooldown_clock.start(2.5)
	pass

func _on_cooldown_clock_time_expired() -> void:
	task_switching_enabled = true
	pass
#endregion

func _on_entered_player_scanner_profile() -> void:
	switch_task(TASKS.MOVE_TO_INTERCEPT)
	pass

func _on_exited_player_scanner_profile() -> void:
	last_player_position = player.position
	switch_task(TASKS.MOVE_TO_RE_DISCOVER)
	pass
