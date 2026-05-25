extends AIUnitAPI
class_name theatreMilitaryUnitAPI

enum TASKS {USE_LIDAR, MOVE_TO_LIDAR, INVESTIGATE_LIDAR, MOVE_TO_INTERCEPT, INTERCEPT, RELOCATE, MOVE_TO_RALLY_POINT_A, MOVE_TO_RALLY_POINT_B, LOOK_FOR_GOAL}
const task_schedule: Dictionary = {
	TASKS.USE_LIDAR: [TASKS.MOVE_TO_RALLY_POINT_A],
	TASKS.MOVE_TO_LIDAR: [TASKS.INVESTIGATE_LIDAR],
	TASKS.INVESTIGATE_LIDAR: [TASKS.MOVE_TO_RALLY_POINT_A],
	TASKS.MOVE_TO_INTERCEPT: [TASKS.INTERCEPT],
	TASKS.INTERCEPT: [TASKS.RELOCATE],
	TASKS.RELOCATE: [TASKS.MOVE_TO_RALLY_POINT_A],
	TASKS.MOVE_TO_RALLY_POINT_A: [TASKS.MOVE_TO_RALLY_POINT_B],
	TASKS.MOVE_TO_RALLY_POINT_B: [TASKS.MOVE_TO_RALLY_POINT_A, TASKS.MOVE_TO_RALLY_POINT_A, TASKS.USE_LIDAR],
	TASKS.LOOK_FOR_GOAL: [TASKS.MOVE_TO_RALLY_POINT_A, TASKS.USE_LIDAR]
}

@export_storage var current_task: TASKS

@export_storage var speed_clock: clock

@export_storage var propensity_to_boost: float = 0.0 #has to be above 1.0 to boost
@export_storage var initial_speed: int
@export_storage var velocity_position_hint: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO] #goal position last frame, self position last frame
@export_storage var within_player_profile: bool:
	set(value):
		if within_player_profile != value:
			match value:
				true:
					_on_entered_player_scanner_profile()
				false:
					_on_exited_player_scanner_profile()
		within_player_profile = value
@export_storage var within_player_power: bool:
	set(value):
		if within_player_power != value:
			match value:
				true:
					_on_entered_player_scanner_power()
				false:
					_on_exited_player_scanner_power()
		within_player_power = value

const MAX_SONAR_LENGTH := 300.0 #currently what it is in sonar_interface, but if i ever change it...

@export_storage var ids_last_contacts : Array[int] = []

@export_storage var goal_id: int
var goal: unitBodyAPI:
	set(value):
		if value != null:
			goal_id = value.get_identifier()
		goal = value
	get():
		if goal != null:
			return goal
		elif goal_id != 0:
			var reclaim_goal = system.get_body_from_identifier(goal_id)
			goal = reclaim_goal
			return goal
		else:
			return null
@export_storage var last_goal_position: Vector2

@export_storage var rally_point_id: int
var rally_point: AIUnitAPI:
	set(value):
		if value != null:
			rally_point_id = value.get_identifier()
		rally_point = value
	get():
		if rally_point != null:
			return rally_point
		elif rally_point_id != 0:
			var reclaim_rally_point = system.get_body_from_identifier(rally_point_id)
			rally_point = reclaim_rally_point
			return rally_point
		else:
			return null

@export var hostile_affiliations: Array = []

func _init() -> void:
	task_clock = clock.new()
	cooldown_clock = clock.new()
	stun_clock = clock.new()
	speed_clock = clock.new()
	pass

func initialize() -> void:
	initial_speed = speed
	pass

func get_connection_pairs() -> Dictionary:
	var connections: Dictionary = {
		cooldown_clock.time_expired: _on_cooldown_clock_time_expired,
		stun_clock.time_expired: _on_stun_clock_time_expired,
		boosting_changed: _on_boosting_changed,
		speed_clock.time_expired: _on_speed_clock_time_expired
	}
	return connections

func advance(delta) -> void:
	task_clock.tick(delta)
	cooldown_clock.tick(delta)
	stun_clock.tick(delta)
	speed_clock.tick(delta)
	
	calculate_asteroid_belt_slowdown()
	update_boosting_status(delta)
	process_scanner_contacts()
	
	match current_task:
		TASKS.MOVE_TO_INTERCEPT, TASKS.INTERCEPT when not is_hostile():
			switch_task(TASKS.RELOCATE)
		TASKS.MOVE_TO_INTERCEPT when goal != null:
			var goal_displacement = goal.position - velocity_position_hint[0]
			var goal_velocity = goal_displacement / delta
			var displacement = position - velocity_position_hint[1]
			var velocity = displacement / delta
			var adjusted_target_position = goal.position + (goal_velocity * (goal_velocity - velocity).length() / (pow(get_adjusted_speed(), 2)))
			target_position = adjusted_target_position
			velocity_position_hint[0] = goal.position
			velocity_position_hint[1] = position
	
	var status = check_task_status()
	if cooldown_clock.is_stopped():
		if status in [TASK_STATUSES.COMPLETE, TASK_STATUSES.FAILED]:
			print("UNIT (%s): TASK %s -> %s" % [self, TASKS.find_key(current_task), TASK_STATUSES.find_key(status)])
			switch_task()
	pass

func update_boosting_status(delta) -> void:
	match current_task:
		TASKS.MOVE_TO_INTERCEPT:
			propensity_to_boost += global_data.get_randf(0.1,1.0) * 10.0 * delta
		TASKS.MOVE_TO_LIDAR, TASKS.RELOCATE, TASKS.MOVE_TO_RALLY_POINT_A, TASKS.MOVE_TO_RALLY_POINT_B, TASKS.LOOK_FOR_GOAL:
			propensity_to_boost += global_data.get_randf(0.0,1.0) * 10.0 * delta
		TASKS.USE_LIDAR, TASKS.INVESTIGATE_LIDAR, TASKS.INTERCEPT:
			propensity_to_boost = 0.0
	
	propensity_to_boost = maxf(0, propensity_to_boost - global_data.get_randf(0.0,1.0) * 10.0 * delta)
	
	if propensity_to_boost >= 1.0:
		boosting = true
	else:
		boosting = false
	pass

func process_scanner_contacts() -> void:
	if player != null:
		var player_profile_contacts = system.get_units_in_scanner_range(player.position, player.get_adjusted_scanner_profile())
		within_player_profile = player_profile_contacts.has(self)
		
		var player_power_contacts = system.get_units_in_scanner_range(player.position, player.get_adjusted_scanner_power())
		within_player_power = player_power_contacts.has(self)
		
	
	var ids_contacts : Array[int] = []
	var contacts : Array[unitBodyAPI] = system.get_units_in_scanner_range(position, 25.0)
	for c in contacts:
		if c != self:
			ids_contacts.append(c.get_identifier())
	
	if ids_contacts.size() != ids_last_contacts.size():
		var ids_gained_contacts = ids_contacts.filter(func(id): return not ids_last_contacts.has(id))
		
		for id in ids_gained_contacts:
			var unit = system.get_body_from_identifier(id)
			if unit != null:
				if unit.metadata.get("affiliation") in hostile_affiliations and randf() > 0.5:
					async_switch_to_intercept(unit)
					break
	
	ids_last_contacts.clear()
	ids_last_contacts.append_array(ids_contacts)
	pass

func check_task_status() -> TASK_STATUSES:
	match current_task:
		TASKS.USE_LIDAR:
			if get_current_action_type() == ACTION_TYPES.NONE:
				if task_clock.is_stopped():
					if sonar_theorised_hostile():
						switch_task(TASKS.MOVE_TO_LIDAR)
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.MOVE_TO_LIDAR, TASKS.MOVE_TO_RALLY_POINT_A, TASKS.MOVE_TO_RALLY_POINT_B:
			if get_current_action_type() == ACTION_TYPES.NONE:
				if position.distance_to(target_position) < starSystemAPI.get_default_radius_solar_radii():
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.INVESTIGATE_LIDAR, TASKS.INTERCEPT, TASKS.RELOCATE, TASKS.LOOK_FOR_GOAL:
			if get_current_action_type() == ACTION_TYPES.NONE:
				if task_clock.is_stopped():
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.MOVE_TO_INTERCEPT:
			if get_current_action_type() == ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
				if (position.distance_to(goal.position) < (goal.radius + 1.0)):
					if goal == player and player.is_invulnerable():
						return TASK_STATUSES.ONGOING
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
		TASKS.USE_LIDAR:
			task_clock.start(15.0)
			emit_signal("play_sound", "res://sound/game/bodyAPIs/unitAPIs/LIDAR_unit_suite.tres", -12.0, "SFX")
			course_to_position(position)
		TASKS.MOVE_TO_LIDAR:
			if last_goal_position != Vector2.ZERO:
				course_to_position(last_goal_position)
		TASKS.INVESTIGATE_LIDAR:
			task_clock.start(global_data.get_randf(5.0, 7.5))
			course_to_position(position)
		TASKS.MOVE_TO_INTERCEPT:
			set_action_type(ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE, null)
		TASKS.INTERCEPT:
			course_to_position(position)
			emit_signal("followingBody", goal)
			task_clock.start(5.0) #(physical) cooldown time before it can move to intercept again
		TASKS.RELOCATE:
			task_clock.start(global_data.get_randf(10.0, 15.0))
			var dir = Vector2.UP.rotated(deg_to_rad(global_data.get_randi(0,360)))
			var pos = goal.position + (dir * 100.0)
			course_to_position(pos)
		TASKS.MOVE_TO_RALLY_POINT_A:
			var dir = Vector2.UP.rotated(deg_to_rad(global_data.get_randi(0,360)))
			var pos = rally_point.position + (dir * 200.0)
			course_to_position(pos)
		TASKS.MOVE_TO_RALLY_POINT_B:
			var dir = Vector2.UP.rotated(deg_to_rad(global_data.get_randi(0,360)))
			var pos = rally_point.position + (dir * 2.0)
			course_to_position(pos)
		TASKS.LOOK_FOR_GOAL:
			task_clock.start(global_data.get_randf(5.0,20.0))
			var dir = position.direction_to(last_goal_position)
			var course = position + (dir * 1000.0)
			course_to_position(course)
	
	print("UNIT (%s): NEW TASK -> %s" % [self, TASKS.find_key(new_task)])
	
	start_cooldown()
	current_task = new_task
	propensity_to_boost = 0.0
	#metadata["_current_task"] = TASKS.find_key(current_task)
	pass


#MISC FUNCTIONS
func sonar_theorised_hostile() -> bool:
	var units = system.get_units()
	units.append(player)
	units.shuffle()
	for unit in units:
		if unit.metadata.get("affiliation") in hostile_affiliations:
			if position.distance_to(unit.position) < MAX_SONAR_LENGTH:
				if randf() > 0.25:
					last_goal_position = unit.position
					return true
	return false

func async_switch_to_intercept(new_goal: unitBodyAPI) -> void:
	if is_hostile():
		if not cooldown_clock.is_stopped():
			await cooldown_clock.time_expired
		goal = new_goal
		switch_task(TASKS.MOVE_TO_INTERCEPT)
	pass

func async_switch_to_re_discover(pos: Vector2) -> void:
	if is_hostile():
		if not cooldown_clock.is_stopped():
			await cooldown_clock.time_expired
		last_goal_position = pos
		switch_task(TASKS.LOOK_FOR_GOAL)
	pass

func stun(duration: float = 1.0, disable_sfx: bool = false) -> void:
	if is_hostile():
		if not is_stunned():
			set_stunned(true)
			stun_clock.start(duration)
			if not disable_sfx:
				emit_signal("play_sound", "res://sound/game/bodyAPIs/unitAPIs/stun.wav", -12.0, "SFX")
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
	if randf() > 0.5:
		async_switch_to_intercept(player)
	pass

func _on_exited_player_scanner_profile() -> void:
	if goal == player:
		async_switch_to_re_discover(player.position)
	pass

func _on_entered_player_scanner_power() -> void:
	speed = initial_speed
	pass

func _on_exited_player_scanner_power() -> void:
	speed_clock.start(10.0)
	pass

func _on_boosting_changed(new_value: bool):
	match new_value:
		true:
			propensity_to_boost += 0.5
		false:
			propensity_to_boost = 0.0
	pass

func _on_stun_clock_time_expired() -> void:
	set_stunned(false)
	pass

func _on_speed_clock_time_expired() -> void:
	if not within_player_power:
		speed = 20
	pass
