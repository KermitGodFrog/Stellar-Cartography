extends AIUnitAPI
class_name theatreMilitaryUnitAPI

enum TASKS {MOVE_TO_WAIT, WAIT, USE_LIDAR, MOVE_TO_LIDAR, INVESTIGATE_LIDAR, MOVE_TO_INTERCEPT, INTERCEPT, RUN, PROCEED_TO_RALLY_POINT, HARASS_PLAYER}
const task_schedule: Dictionary = {
	TASKS.MOVE_TO_WAIT: [TASKS.WAIT],
	TASKS.WAIT: [TASKS.MOVE_TO_WAIT, TASKS.USE_LIDAR, TASKS.PROCEED_TO_RALLY_POINT, TASKS.HARASS_PLAYER],
	TASKS.USE_LIDAR: [TASKS.MOVE_TO_WAIT, TASKS.PROCEED_TO_RALLY_POINT, TASKS.HARASS_PLAYER],
	TASKS.MOVE_TO_LIDAR: [TASKS.INVESTIGATE_LIDAR],
	TASKS.INVESTIGATE_LIDAR: [TASKS.MOVE_TO_WAIT, TASKS.USE_LIDAR, TASKS.PROCEED_TO_RALLY_POINT, TASKS.HARASS_PLAYER],
	TASKS.MOVE_TO_INTERCEPT: [TASKS.INTERCEPT],
	TASKS.INTERCEPT: [TASKS.MOVE_TO_INTERCEPT, TASKS.RUN],
	TASKS.RUN: [TASKS.PROCEED_TO_RALLY_POINT],
	TASKS.PROCEED_TO_RALLY_POINT: [TASKS.PROCEED_TO_RALLY_POINT, TASKS.USE_LIDAR, TASKS.HARASS_PLAYER],
	TASKS.HARASS_PLAYER: [TASKS.HARASS_PLAYER, TASKS.USE_LIDAR, TASKS.PROCEED_TO_RALLY_POINT]
}

@export_storage var current_task: TASKS

@export_storage var propensity_to_boost: float = 0.0 #has to be above 1.0 to boost

@export var valid_wait_target_ids: Array[int] = []
const MAX_VALID_PLANETS: int = 2
const MAX_VALID_RIFT_DRIVERS: int = 1

const MAX_SONAR_LENGTH := 300.0 #currently what it is in sonar_interface, but if i ever change it...

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
@export_storage var last_goal_position

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

@export var hostile_affilications: Array[game_data.UNIT_AFFILIATIONS] = []

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
	
	var status = check_task_status()
	if cooldown_clock.is_stopped():
		if status in [TASK_STATUSES.COMPLETE, TASK_STATUSES.FAILED]:
			print("UNIT (%s): TASK %s -> %s" % [self, TASKS.find_key(current_task), TASK_STATUSES.find_key(status)])
			switch_task()
	pass

func update_boosting_status(delta) -> void:
	#match current_task:
		#propensity_to_boost += global_data.get_randf(0.0,1.0) * 10.0 * delta
		#propensity_to_boost = 0.0
	
	propensity_to_boost = maxf(0, propensity_to_boost - global_data.get_randf(0.0,1.0) * 10.0 * delta)
	
	if propensity_to_boost >= 1.0:
		boosting = true
	else:
		boosting = false
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
					if sonar_theorised_hostile():
						switch_task(TASKS.MOVE_TO_LIDAR)
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.MOVE_TO_LIDAR:
			if get_current_action_type() == ACTION_TYPES.NONE:
				if position.distance_to(target_position) < starSystemAPI.get_default_radius_solar_radii():
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.INVESTIGATE_LIDAR, TASKS.INTERCEPT, TASKS.RUN, TASKS.PROCEED_TO_RALLY_POINT:
			if get_current_action_type() == ACTION_TYPES.NONE:
				if task_clock.is_stopped():
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.MOVE_TO_INTERCEPT:
			if get_current_action_type() == ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
				if (position.distance_to(player.position) < (player.radius + 1.0)) and not player.is_invulnerable():
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
			task_clock.start(global_data.get_randf(10.0,30.0))
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
		TASKS.RUN:
			task_clock.start(global_data.get_randf(10.0, 15.0))
			if goal:
				var dir = Vector2.UP.rotated(deg_to_rad(global_data.get_randi(0,360)))
				var run_position = goal.position + (dir * 100.0)
				course_to_position(run_position)
		TASKS.PROCEED_TO_RALLY_POINT:
			task_clock.start(global_data.get_randf(10.0, 15.0))
			if rally_point:
				var dir = Vector2.UP.rotated(deg_to_rad(global_data.get_randi(0,360)))
				var offset_position = rally_point.position + (dir * 2.0)
				course_to_position(offset_position)
		TASKS.HARASS_PLAYER:
			task_clock.start(global_data.get_randf(10.0, 15.0))
			var dir = Vector2.UP.rotated(deg_to_rad(global_data.get_randi(0,360)))
			var offset_position = player.position + (dir * global_data.get_randf(0.0, 10.0))
			var final_position = offset_position + (offset_position.direction_to(position) * 100.0)
			course_to_position(final_position)
	
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
	var rift_drivers: Array[customBodyAPI] = []
	for b in system.get_bodies_of_body_type(starSystemAPI.BODY_TYPES.CUSTOM):
		if b.get_dialogue_tag() in ["riftDriver", "insaRiftDriver"]:
			rift_drivers.append(b)
	
	for i in range(MAX_VALID_PLANETS):
		if planets.size() > 0:
			var planet = planets.pick_random()
			if planet.get_display_name() == "Kalama":
				if system.special_system_classification == game_data.SPECIAL_SYSTEM_CLASSIFICATIONS.INSA:
					planets.erase(planet)
					continue
			valid_wait_target_ids.append(planet.get_identifier())
			planets.erase(planet)
	
	for i in range(MAX_VALID_RIFT_DRIVERS):
		if rift_drivers.size() > 0:
			var driver = rift_drivers.pick_random()
			valid_wait_target_ids.append(driver.get_identifier())
			rift_drivers.erase(driver)
	
	valid_wait_target_ids.append(system.get_first_star().get_identifier())
	pass

func sonar_theorised_hostile() -> bool:
	if position.distance_to(player.position) < MAX_SONAR_LENGTH:
		if randf() > 0.5:
			last_goal_position = player.position
			return true
	else:
		for unit in system.get_units():
			if unit.metadata.get("affiliation") in hostile_affilications:
				if position.distance_to(unit.position) < MAX_SONAR_LENGTH:
					if randf() > 0.25:
						last_goal_position = unit.position
						return true
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

func _on_boosting_changed(new_value: bool):
	match new_value:
		true:
			propensity_to_boost += 0.5
		false:
			propensity_to_boost = 0.0
	pass
