extends AIUnitAPI
class_name lightGremlinUnitAPI

enum TASKS {RECHARGE, MOVE_TO_PLAY, PLAY_A, PLAY_B, PLAY_C, PLAY_D, PLAY_E, MOVE_TO_ORBIT, ORBIT}
const task_schedule: Dictionary = {
	TASKS.RECHARGE: [TASKS.MOVE_TO_PLAY],
	TASKS.MOVE_TO_PLAY: [TASKS.PLAY_A, TASKS.PLAY_B, TASKS.PLAY_C, TASKS.PLAY_D, TASKS.PLAY_E],
	TASKS.PLAY_A: [TASKS.MOVE_TO_PLAY, TASKS.RECHARGE, TASKS.MOVE_TO_ORBIT, TASKS.ORBIT], #parabola close to the player
	TASKS.PLAY_B: [TASKS.MOVE_TO_PLAY, TASKS.RECHARGE, TASKS.MOVE_TO_ORBIT], #circle
	TASKS.PLAY_C: [TASKS.MOVE_TO_PLAY, TASKS.RECHARGE, TASKS.MOVE_TO_ORBIT], #circle with jutted out points closer to the player like a sawtooth
	TASKS.PLAY_D: [TASKS.MOVE_TO_PLAY, TASKS.RECHARGE, TASKS.MOVE_TO_ORBIT, TASKS.ORBIT], #spiral
	TASKS.PLAY_E: [TASKS.MOVE_TO_PLAY, TASKS.RECHARGE, TASKS.MOVE_TO_ORBIT], #quadratic bezier flyby
	TASKS.MOVE_TO_ORBIT: [TASKS.ORBIT],
	TASKS.ORBIT: [TASKS.MOVE_TO_PLAY, TASKS.RECHARGE]
}

#core customisation \
@export var energy_loss_multiplier: float = 1.0
@export var max_energy: float = 60.0
@export var personality: PERSONALITIES = PERSONALITIES.BALANCED
@export var silly: bool = true

#other \
@export_storage var current_energy: float = max_energy:
	set(value):
		current_energy = value
		if current_energy < get_low_energy_theshold():
			_on_energy_low()
var current_energy_index: float:
	get():
		return remap(current_energy, 0.0, max_energy, 0.0, 1.0)

@export_storage var motion_points: Array[Vector2] = [] #when used by 'play' these are relative to player pos, but not when 'orbit'
@export_storage var cached_target_position: Vector2
@export_storage var sys_max_orbit_distance: float = 0.0
@export_storage var name_locked: bool = false

#resources \
var energy_to_speed_curve: Curve = preload("uid://ddvq4bv6m1tpe")
enum PERSONALITIES {
	CAUTIOUS,
	BALANCED,
	DAREDEVIL
}

func initialize() -> void:
	sys_max_orbit_distance = system.get_max_body_orbit_distance()
	pass

func advance(delta) -> void:
	super(delta)
	
	if (metadata.get("ship_available", true) == false) and not name_locked:
		set_display_name("Light Gremlin %03d" % global_data.get_randi(0, 999))
		name_locked = true
	
	var distance_to_star: float = system.get_first_star().position.distance_to(position)
	var distance_index: float = remap(distance_to_star, 0.0, sys_max_orbit_distance, 0.0, 1.0)
	current_energy = maxf(0.0, current_energy - (distance_index * energy_loss_multiplier * delta))
	speed = roundi(energy_to_speed_curve.sample(remap(current_energy, 0.0, max_energy, 0.0, 1.0)))
	
	if current_task in [TASKS.RECHARGE, TASKS.MOVE_TO_ORBIT, TASKS.ORBIT] and player != null:
		if player.position.distance_to(position) < get_min_distance():
			var travel_vector = (player.position.direction_to(position)) * 100.0
			target_position = position + travel_vector
			return
	
	match current_task:
		TASKS.MOVE_TO_PLAY, TASKS.PLAY_A, TASKS.PLAY_B, TASKS.PLAY_C, TASKS.PLAY_D, TASKS.PLAY_E when not silly:
			switch_task(TASKS.MOVE_TO_ORBIT)
		TASKS.RECHARGE:
			cached_target_position = system.get_first_star().position.direction_to(position) * get_adj_recharge_distance()
			target_position = cached_target_position
			if position.distance_to(cached_target_position) < (starSystemAPI.get_default_radius_solar_radii() + 5.0):
				current_energy = minf(max_energy, current_energy + (distance_index * 5.0 * delta))
		TASKS.MOVE_TO_PLAY:
			target_position = player.position + (player.position.direction_to(position) * get_min_distance())
		TASKS.PLAY_A, TASKS.PLAY_B, TASKS.PLAY_C, TASKS.PLAY_D, TASKS.PLAY_E:
			if motion_points.size() > 0:
				var rel_active_point: Vector2 = player.position + motion_points.front()
				target_position = rel_active_point
				if position.distance_to(rel_active_point) < (starSystemAPI.get_default_radius_solar_radii() + 1.0):
					motion_points.pop_front()
		TASKS.MOVE_TO_ORBIT:
			target_position = cached_target_position
		TASKS.ORBIT:
			if motion_points.size() > 0:
				var active_point: Vector2 = motion_points.front()
				target_position = active_point + position.direction_to(active_point) * 100.0
				if position.distance_to(active_point) < (starSystemAPI.get_default_radius_solar_radii() + 1.0):
					motion_points.pop_front()
	pass

func check_task_status() -> TASK_STATUSES:
	match current_task:
		TASKS.RECHARGE:
			if get_current_action_type() == ACTION_TYPES.NONE:
				if current_energy > (max_energy * 0.9):
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.MOVE_TO_PLAY:
			if get_current_action_type() == ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
				if position.distance_to(target_position) < get_min_distance():
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.PLAY_A, TASKS.PLAY_B, TASKS.PLAY_C, TASKS.PLAY_D, TASKS.PLAY_E:
			if get_current_action_type() == ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
				if task_clock.is_stopped() or motion_points.is_empty():
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.MOVE_TO_ORBIT:
			if get_current_action_type() == ACTION_TYPES.NONE:
				if position.distance_to(cached_target_position) < (starSystemAPI.get_default_radius_solar_radii() + 1.0):
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.ORBIT:
			if get_current_action_type() == ACTION_TYPES.NONE:
				if task_clock.is_stopped() or motion_points.is_empty():
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
	return TASK_STATUSES.FAILED

func switch_task(override_task = null) -> int:
	var new_task = super(override_task)
	
	motion_points.clear()
	
	set_action_type(ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE, null)
	match new_task: # EVERYTHING is updated in advance since these creatures NEED to be dynamic!!!
		TASKS.RECHARGE:
			set_action_type(ACTION_TYPES.NONE, null)
		TASKS.MOVE_TO_PLAY:
			pass
		TASKS.PLAY_A:
			task_clock.start(10.0)
			var random_rotation := global_data.get_random_rotation()
			const sample_count := 20
			var half_count: int = sample_count / 2
			var m: float = global_data.get_randf(0.05, 1.0)
			for x in range(-half_count, half_count + 1):
				var y: float = m * pow(x, 2) - get_min_distance() #y = mx^2 + b
				motion_points.append(Vector2(x, y).rotated(random_rotation))
		TASKS.PLAY_B:
			task_clock.start(10.0)
			var spin_count: int = global_data.get_randi(3, 10)
			const sample_count := 21
			for i in spin_count:
				for s in sample_count:
					var rad_theta = deg_to_rad((360 / sample_count) * s)
					var x = get_min_distance() * cos(rad_theta)
					var y = get_min_distance() * sin(rad_theta)
					motion_points.append(Vector2(x, y))
		TASKS.PLAY_C:
			task_clock.start(10.0)
			var spin_count: int = global_data.get_randi(3, 5)
			const sample_count := 42
			var gain_samples: Array[int] = []
			for s in sample_count:
				if gain_samples.has(s-1):
					if randf() > 0.05:
						gain_samples.append(s)
				elif randf() > 0.50:
					gain_samples.append(s)
			for i in spin_count:
				for s in sample_count:
					var temporary_gain: float = 0.0
					if gain_samples.has(s):
						temporary_gain += get_min_distance() / 2
					var rad_theta = deg_to_rad((360 / sample_count) * s)
					var x = (get_min_distance() + temporary_gain) * cos(rad_theta)
					var y = (get_min_distance() + temporary_gain) * sin(rad_theta)
					motion_points.append(Vector2(x, y))
		TASKS.PLAY_D:
			task_clock.start(10.0)
			var spin_count: int = global_data.get_randi(1, 5)
			const sample_count := 21
			var gain: float = global_data.get_randf(0.1, 2.5)
			for i in spin_count:
				for s in sample_count:
					var rad_theta = deg_to_rad((360 / sample_count) * s)
					var existing_s = i * sample_count
					var x = (get_min_distance() + (gain * (s + existing_s))) * cos(rad_theta)
					var y = (get_min_distance() + (gain * (s + existing_s))) * sin(rad_theta)
					motion_points.append(Vector2(x, y))
		TASKS.PLAY_E:
			task_clock.start(10.0)
			const sample_count := 40
			var points: Array[Vector2] = []
			var last_rotation := global_data.get_random_rotation()
			var last_distance: float = global_data.get_randf(get_min_distance() * 2, get_min_distance() * 2 + 20.0)
			for i in 3:
				var new_rotation := last_rotation + deg_to_rad(global_data.get_randf(5.0, 45.0))
				var new_distance = last_distance + global_data.get_randf(get_min_distance(), get_min_distance() + 50.0)
				points.append((Vector2.UP * new_distance).rotated(new_rotation))
				last_rotation = new_rotation
				last_distance = new_distance
			for s in range(0, sample_count):
				motion_points.append((position - player.position).bezier_interpolate(points[0], points[1], points[2], remap(s, 0, sample_count, 0.0, 1.0)))
		TASKS.MOVE_TO_ORBIT:
			set_action_type(ACTION_TYPES.NONE, null)
			cached_target_position = system.get_random_interior_position()
		TASKS.ORBIT:
			set_action_type(ACTION_TYPES.NONE, null)
			const sample_count := 20
			var control_1 := system.get_random_interior_position()
			var control_2 := system.get_random_interior_position()
			var end := system.get_random_interior_position()
			for s in range(0, sample_count):
				motion_points.append(position.bezier_interpolate(control_1, control_2, end, remap(s, 0, sample_count, 0.0, 1.0)))
			task_clock.start(30.0)
	
	#metadata["_current_task"] = TASKS.find_key(current_task)
	return new_task




#misc 

func get_tasks() -> Dictionary:
	return TASKS

func get_task_schedule() -> Dictionary:
	return task_schedule

func get_adj_recharge_distance() -> float:
	var data: Dictionary = {
		PERSONALITIES.CAUTIOUS: sys_max_orbit_distance * 0.25,
		PERSONALITIES.BALANCED: sys_max_orbit_distance * 0.1,
		PERSONALITIES.DAREDEVIL: sys_max_orbit_distance * 0.05,
	}
	var base_distance: float = data.get(personality)
	var adj_distance: float = move_toward(base_distance, sys_max_orbit_distance * 0.01, current_energy_index) #the more desperate a light gremlin is, the more risks they will take
	return adj_distance

func get_min_distance() -> float:
	var data: Dictionary = {
		PERSONALITIES.CAUTIOUS: 15.0,
		PERSONALITIES.BALANCED: 7.5,
		PERSONALITIES.DAREDEVIL: 5.0
	}
	return data.get(personality)

func get_low_energy_theshold() -> float:
	var data: Dictionary = {
		PERSONALITIES.CAUTIOUS: max_energy * 0.6,
		PERSONALITIES.BALANCED: max_energy * 0.5,
		PERSONALITIES.DAREDEVIL: max_energy * 0.4
	}
	return data.get(personality)

func _on_energy_low() -> void:
	if current_task != TASKS.RECHARGE:
		if not cooldown_clock.is_stopped():
			await cooldown_clock.time_expired
			switch_task(TASKS.RECHARGE)
		else:
			switch_task(TASKS.RECHARGE)
	pass

func force_replenish_all_energy() -> void:
	current_energy = max_energy
	pass
