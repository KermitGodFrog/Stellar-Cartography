extends AIUnitAPI
class_name interceptingUnitAPI

enum TASKS {MOVE_TO_WAIT, WAIT, USE_LIDAR, MOVE_TO_LIDAR, INVESTIGATE_LIDAR, MOVE_TO_INTERCEPT, INTERCEPT, LOOK_FOR_PLAYER, LOOK_FOR_PLAYER_ALT}
const task_schedule: Dictionary = {
	TASKS.MOVE_TO_WAIT: [TASKS.WAIT],
	TASKS.WAIT: [TASKS.MOVE_TO_WAIT, TASKS.USE_LIDAR],
	TASKS.USE_LIDAR: [TASKS.MOVE_TO_WAIT], #maybe make this play a sound?? not sureeee...
	TASKS.MOVE_TO_LIDAR: [TASKS.INVESTIGATE_LIDAR], #overrides if 'USE_LIDAR' by chance finds the player 
	TASKS.INVESTIGATE_LIDAR: [TASKS.MOVE_TO_WAIT, TASKS.USE_LIDAR],
	TASKS.MOVE_TO_INTERCEPT: [TASKS.INTERCEPT], #overrides if ENTERING the players scanner profile
	TASKS.INTERCEPT: [TASKS.MOVE_TO_INTERCEPT],
	TASKS.LOOK_FOR_PLAYER: [TASKS.LOOK_FOR_PLAYER_ALT, TASKS.USE_LIDAR], #overrides if EXITING the players scanner profile. follows the players dir vector for 1 minute and then ceases
	TASKS.LOOK_FOR_PLAYER_ALT: [TASKS.LOOK_FOR_PLAYER_ALT, TASKS.MOVE_TO_WAIT, TASKS.USE_LIDAR]
}
@export_storage var current_task: TASKS

@export_storage var last_player_position: Vector2 = Vector2.ZERO
@export_storage var within_player_profile: bool:
	set(value):
		if within_player_profile != value:
			match value:
				true:
					_on_entered_player_scanner_profile()
				false:
					_on_exited_player_scanner_profile()
		within_player_profile = value
@export_storage var propensity_to_boost: float = 0.0 #has to be above 1.0 to boost
@export_storage var velocity_position_hint: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO] #player position last frame, self position last frame

@export var valid_wait_target_ids: Array[int] = []
const MAX_VALID_PLANETS: int = 3
const MAX_VALID_WORMHOLES: int = 1

const MAX_SONAR_LENGTH := 300.0 #currently what it is in sonar_interface, but if i ever change it...

func _init() -> void:
	task_clock = clock.new()
	cooldown_clock = clock.new()
	pass

func initialize() -> void:
	cooldown_clock.time_expired.connect(_on_cooldown_clock_time_expired)
	boosting_changed.connect(_on_boosting_changed)
	pass

func advance(delta) -> void:
	task_clock.tick(delta)
	cooldown_clock.tick(delta)
	
	calculate_asteroid_belt_slowdown()
	update_boosting_status(delta)
	update_scanner_status()
	
	match current_task:
		TASKS.MOVE_TO_INTERCEPT:
			var player_displacement = player.position - velocity_position_hint[0]
			var player_velocity = player_displacement / delta
			var displacement = position - velocity_position_hint[1]
			var velocity = displacement / delta
			var adjusted_target_position = player.position + (player_velocity * (player_velocity - velocity).length() / (pow(get_adjusted_speed(), 2)))
			target_position = adjusted_target_position
	
	var status = check_task_status()
	if cooldown_clock.is_stopped():
		if status in [TASK_STATUSES.COMPLETE, TASK_STATUSES.FAILED]:
			print("UNIT (%s): TASK %s -> %s" % [self, TASKS.find_key(current_task), TASK_STATUSES.find_key(status)])
			switch_task()
	velocity_position_hint[0] = player.position
	velocity_position_hint[1] = position
	pass

func update_boosting_status(delta) -> void:
	match current_task:
		TASKS.MOVE_TO_INTERCEPT:
			propensity_to_boost += global_data.get_randf(0.1,1.0) * 10.0 * delta
		TASKS.MOVE_TO_WAIT, TASKS.MOVE_TO_LIDAR, TASKS.LOOK_FOR_PLAYER, TASKS.LOOK_FOR_PLAYER_ALT:
			propensity_to_boost += global_data.get_randf(0.0,1.0) * 10.0 * delta
		TASKS.WAIT, TASKS.USE_LIDAR, TASKS.INVESTIGATE_LIDAR, TASKS.INTERCEPT:
			propensity_to_boost = 0.0
	
	propensity_to_boost = maxf(0, propensity_to_boost - global_data.get_randf(0.0,1.0) * 10.0 * delta)
	
	if propensity_to_boost >= 1.0:
		boosting = true
	else:
		boosting = false
	pass

func update_scanner_status() -> void:
	var contacts = system.get_units_in_scanner_range(player.position, player.scanner_profile)
	within_player_profile = contacts.has(self)
	pass

func check_task_status() -> TASK_STATUSES:
	match current_task:
		TASKS.MOVE_TO_WAIT:
			if target != null:
				if is_action_pending():
					if pending_action_body == target:
						return TASK_STATUSES.ONGOING
				elif not is_action_pending():
					if action_body == target:
						return TASK_STATUSES.COMPLETE
			return TASK_STATUSES.FAILED
		TASKS.WAIT:
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
		TASKS.INVESTIGATE_LIDAR, TASKS.LOOK_FOR_PLAYER, TASKS.LOOK_FOR_PLAYER_ALT, TASKS.INTERCEPT:
			if get_current_action_type() == ACTION_TYPES.NONE:
				if task_clock.is_stopped():
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.MOVE_TO_LIDAR:
			if get_current_action_type() == ACTION_TYPES.NONE:
				if position.distance_to(target_position) < system.get_default_radius_solar_radii(): #assumes that the players radius is the default
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.MOVE_TO_INTERCEPT:
			if get_current_action_type() == ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
				if position.distance_to(player.position) < (player.radius + 1.0): #assumes that the players radius is the default
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
		TASKS.MOVE_TO_WAIT:
			target = null
			if valid_wait_target_ids.size() > 0:
				var new_target_id = valid_wait_target_ids.pick_random()
				var new_target = system.get_body_from_identifier(new_target_id)
				target = new_target
				orbit_body(target)
		TASKS.WAIT:
			task_clock.start(global_data.get_randf(30.0,60.0))
		TASKS.USE_LIDAR:
			task_clock.start(15.0)
			emit_signal("play_sound", "res://sound/game/bodyAPIs/unitAPIs/LIDAR_unit_suite.tres", 0.0, "SFX")
			course_to_position(position)
		TASKS.MOVE_TO_LIDAR:
			if last_player_position != Vector2.ZERO:
				course_to_position(last_player_position)
		TASKS.INVESTIGATE_LIDAR:
			task_clock.start(global_data.get_randf(5.0, 7.5))
			course_to_position(position)
		TASKS.MOVE_TO_INTERCEPT:
			set_action_type(ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE, null) #continuously updated in advance function
		TASKS.INTERCEPT:
			course_to_position(position)
			emit_signal("followingBody", player)
			task_clock.start(5.0) #(physical) cooldown time before it can move to intercept again
		TASKS.LOOK_FOR_PLAYER:
			task_clock.start(global_data.get_randf(5.0,20.0))
			var dir = position.direction_to(last_player_position)
			var course = position + (dir * 1000.0)
			course_to_position(course)
		TASKS.LOOK_FOR_PLAYER_ALT:
			task_clock.start(global_data.get_randf(5.0,10.0))
			var dir = position.direction_to(last_player_position)
			var dir_alt = dir.rotated(deg_to_rad(global_data.get_randf(-45.0, 45.0)))
			dir_alt = dir_alt.normalized()
			var course = position + (dir_alt * 1000.0)
			course_to_position(course)
	
	print("UNIT (%s): NEW TASK -> %s" % [self, TASKS.find_key(new_task)])
	
	start_cooldown()
	current_task = new_task
	propensity_to_boost = 0.0
	metadata["_current_task"] = TASKS.find_key(current_task)
	pass

#MISC FUNCTIONS
func generate_valid_targets() -> void:
	valid_wait_target_ids.clear()
	
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
	pass

func sonar_theorised_player() -> bool:
	if position.distance_to(player.position) < MAX_SONAR_LENGTH:
		var mapped_distance = remap(position.distance_to(player.position), MAX_SONAR_LENGTH, 0, 0.2, 0.75)
		var theorised_player = randf() < mapped_distance
		if theorised_player:
			last_player_position = player.position
		return theorised_player
	return false

func async_switch_to_intercept() -> void:
	switch_task(TASKS.MOVE_TO_INTERCEPT)
	pass

func async_switch_to_re_discover() -> void:
	last_player_position = player.position
	switch_task(TASKS.LOOK_FOR_PLAYER)
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

func _on_entered_player_scanner_profile() -> void:
	if not cooldown_clock.is_stopped():
		await cooldown_clock.time_expired
		async_switch_to_intercept()
	else:
		async_switch_to_intercept()
	pass

func _on_exited_player_scanner_profile() -> void:
	if not cooldown_clock.is_stopped():
		await cooldown_clock.time_expired
		async_switch_to_re_discover()
	else:
		async_switch_to_re_discover()
	pass

func _on_boosting_changed(new_value: bool):
	match new_value:
		true:
			propensity_to_boost += 0.5
		false:
			propensity_to_boost = 0.0
	pass
