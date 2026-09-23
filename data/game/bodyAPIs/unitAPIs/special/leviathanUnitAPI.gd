extends AIUnitAPI
class_name leviathanUnitAPI

enum TASKS {MOVE_TO_WAIT, WAIT, HUNT_FOR_PLAYER, COOL_OFF}
const task_schedule: Dictionary = {
	TASKS.MOVE_TO_WAIT: [TASKS.WAIT],
	TASKS.WAIT: [TASKS.MOVE_TO_WAIT, TASKS.HUNT_FOR_PLAYER],
	TASKS.HUNT_FOR_PLAYER: [TASKS.COOL_OFF],
	TASKS.COOL_OFF: [TASKS.MOVE_TO_WAIT, TASKS.HUNT_FOR_PLAYER]
}

@export_storage var hunt_position: Vector2 = Vector2.ZERO
@export_storage var within_player_profile: bool:
	set(value):
		if within_player_profile != value:
			match value:
				true:
					_on_entered_player_scanner_profile()
		within_player_profile = value

@export var electrical_disruption_radius: float = 10.0

func advance(delta) -> void:
	super(delta)
	
	update_scanner_status()
	
	match current_task:
		TASKS.HUNT_FOR_PLAYER when player != null:
			if hunt_position != Vector2.ZERO:
				target_position = hunt_position
			elif position.distance_to(player.position) > 75:
				target_position = player.position
			else:
				var dir = position.direction_to(player.position)
				hunt_position = player.position + (dir * 100.0)
			
			if target != null:
				target.position = position
				target.exclusion_radius_points = []
	pass

func get_connection_pairs() -> Dictionary:
	var connections: Dictionary = {
		cooldown_clock.time_expired: _on_cooldown_clock_time_expired,
		stun_clock.time_expired: _on_stun_clock_time_expired,
	}
	return connections

func check_task_status() -> TASK_STATUSES:
	match current_task:
		TASKS.MOVE_TO_WAIT:
			if get_current_action_type() == ACTION_TYPES.NONE:
				if position.distance_to(target_position) < starSystemAPI.get_default_radius_solar_radii():
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.HUNT_FOR_PLAYER:
			if get_current_action_type() == ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
				if position.distance_to(target_position) < starSystemAPI.get_default_radius_solar_radii():
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.WAIT, TASKS.COOL_OFF:
			if get_current_action_type() == ACTION_TYPES.NONE:
				if task_clock.is_stopped():
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
	return TASK_STATUSES.ONGOING

func switch_task(override_task = null) -> int:
	var new_task = super(override_task)
	
	hunt_position = Vector2.ZERO
	if target != null:
		system.removeBody(target.get_identifier())
		target = null
	
	match new_task:
		TASKS.MOVE_TO_WAIT:
			course_to_position(position + (Vector2.UP.rotated(deg_to_rad(global_data.get_randf(0.0, 360.0))) * global_data.get_randf(10.0, 100.0)))
		TASKS.WAIT:
			task_clock.start(10.0)
		TASKS.HUNT_FOR_PLAYER:
			set_action_type(ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE, null)
			regenerate_mine()
			#continuously updated in advance()
		TASKS.COOL_OFF:
			course_to_position(position)
			task_clock.start(5.0)
	
	metadata["_current_task"] = TASKS.find_key(current_task)
	return new_task

func update_scanner_status() -> void:
	if player != null:
		var contacts = system.get_units_in_scanner_range(player.position, player.get_adjusted_scanner_profile())
		within_player_profile = contacts.has(self)
	pass







func get_tasks() -> Dictionary:
	return TASKS

func get_task_schedule() -> Dictionary:
	return task_schedule

func stun(duration: float = 1.0) -> void:
	if is_hostile():
		if not is_stunned():
			set_stunned(true)
			stun_clock.start(duration)
			emit_signal("play_sound", "res://sound/game/bodyAPIs/unitAPIs/stun.wav", -12.0, "SFX")
	pass

func _on_stun_clock_time_expired() -> void:
	set_stunned(false)
	pass

func regenerate_mine() -> void:
	var id := system.addUnitBody(
		mineUnitAPI.new(),
		starSystemAPI.BODY_TYPES.MINE,
		system.identifier_count,
		"Leviathan Electrical Disruption Zone",
		0,
		starSystemAPI.get_default_radius_solar_radii(),
		{"position": position, "max_detonation_time": 0.05, "hidden": true},
		{"hostile": true, "exclusion_zone_radius": electrical_disruption_radius}
	)
	target = system.get_body_from_identifier(id)
	pass

func _on_entered_player_scanner_profile() -> void:
	if not cooldown_clock.is_stopped():
		await cooldown_clock.time_expired
		if current_task != TASKS.HUNT_FOR_PLAYER:
			switch_task(TASKS.HUNT_FOR_PLAYER)
	else:
		if current_task != TASKS.HUNT_FOR_PLAYER:
			switch_task(TASKS.HUNT_FOR_PLAYER)
	pass
