extends AIUnitAPI
class_name lightGremlinUnitAPI

enum TASKS {RECHARGE, MOVE_TO_PLAY, PLAY_A, PLAY_B, PLAY_C, PLAY_D, PLAY_E, MOVE_TO_ORBIT, ORBIT}
const task_schedule: Dictionary = {
	TASKS.RECHARGE: [TASKS.MOVE_TO_PLAY],
	#TASKS.MOVE_TO_PLAY: [TASKS.PLAY_A, TASKS.PLAY_B, TASKS.PLAY_C, TASKS.PLAY_D, TASKS.PLAY_E],
	TASKS.MOVE_TO_PLAY: [TASKS.PLAY_A, TASKS.PLAY_B, TASKS.PLAY_C, TASKS.PLAY_D],
	TASKS.PLAY_A: [TASKS.MOVE_TO_PLAY, TASKS.RECHARGE, TASKS.MOVE_TO_ORBIT], #parabola close to the player
	TASKS.PLAY_B: [TASKS.MOVE_TO_PLAY, TASKS.RECHARGE, TASKS.MOVE_TO_ORBIT], #circle
	TASKS.PLAY_C: [TASKS.MOVE_TO_PLAY, TASKS.RECHARGE, TASKS.MOVE_TO_ORBIT], #circle with jutted out points closer to the player like a sawtooth
	TASKS.PLAY_D: [TASKS.MOVE_TO_PLAY, TASKS.RECHARGE, TASKS.MOVE_TO_ORBIT], #spiral
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
		if current_energy < max_energy / 2:
			_on_energy_low()
var current_energy_index: float:
	get():
		return remap(current_energy, 0.0, max_energy, 0.0, 1.0)

@export_storage var play_points: Array[Vector2] = [] #relative to player pos
@export_storage var cached_target_position: Vector2
@export_storage var sys_max_orbit_distance: float = 0.0 #REMINDER THAT THIS HAS TO BE SET WHEN THE BODY IS CREATED!!!

#resources \
var energy_to_speed_curve: Curve = preload("uid://ddvq4bv6m1tpe")
enum PERSONALITIES {
	CAUTIOUS,
	BALANCED,
	DAREDEVIL
}
var personality_data: Dictionary = {
	PERSONALITIES.CAUTIOUS: {"min_distance": 10.0},
	PERSONALITIES.BALANCED: {"min_distance": 5.0},
	PERSONALITIES.DAREDEVIL: {"min_distance": 2.5}
}

func advance(delta) -> void:
	super(delta)
	
	var distance_to_star: float = system.get_first_star().position.distance_to(position)
	var distance_index: float = remap(distance_to_star, 0.0, sys_max_orbit_distance, 0.0, 1.0)
	current_energy = maxf(0.0, current_energy - (distance_index * energy_loss_multiplier * delta))
	
	speed = roundi(energy_to_speed_curve.sample(remap(current_energy, 0.0, max_energy, 0.0, 1.0)))
	
	metadata["_current_energy"] = current_energy
	metadata["_speed"] = speed
	
	if current_task in [TASKS.RECHARGE, TASKS.MOVE_TO_ORBIT, TASKS.ORBIT] and player != null:
		if player.position.distance_to(position) < personality_data.get(personality).get("min_distance"):
			var travel_vector = (player.position.direction_to(position)) * (personality_data.get(personality).get("min_distance") + 1)
			if (position + travel_vector).distance_to(player.position) < starSystemAPI.get_default_radius_solar_radii():
				target_position = position
			else:
				target_position = position + travel_vector
			return
	
	match current_task:
		TASKS.RECHARGE:
			cached_target_position = system.get_first_star().position.direction_to(position) * get_adj_recharge_distance()
			target_position = cached_target_position
			if position.distance_to(cached_target_position) < (starSystemAPI.get_default_radius_solar_radii() + 10.0):
				current_energy = minf(max_energy, current_energy + (distance_index * 5.0 * delta))
		TASKS.MOVE_TO_PLAY:
			target_position = player.position + (player.position.direction_to(position) * personality_data.get(personality).get("min_distance"))
		TASKS.PLAY_A, TASKS.PLAY_B, TASKS.PLAY_C, TASKS.PLAY_D, TASKS.PLAY_E:
			if play_points.size() > 0:
				var adj_active_point: Vector2 = player.position + play_points.front()
				target_position = adj_active_point
				if position.distance_to(adj_active_point) < (starSystemAPI.get_default_radius_solar_radii() + 1.0):
					play_points.pop_front()
		TASKS.MOVE_TO_ORBIT, TASKS.ORBIT:
			target_position = cached_target_position
	pass

func check_task_status() -> TASK_STATUSES:
	match current_task:
		TASKS.RECHARGE:
			if get_current_action_type() == ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
				if current_energy > (max_energy * 0.9):
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.MOVE_TO_PLAY:
			if get_current_action_type() == ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
				if position.distance_to(target_position) < personality_data.get(personality).get("min_distance"):
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.PLAY_A, TASKS.PLAY_B, TASKS.PLAY_C, TASKS.PLAY_D, TASKS.PLAY_E:
			if get_current_action_type() == ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
				if task_clock.is_stopped() or play_points.is_empty():
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.MOVE_TO_ORBIT:
			if get_current_action_type() == ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
				if position.distance_to(cached_target_position) < (starSystemAPI.get_default_radius_solar_radii() + 1.0):
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
		TASKS.ORBIT:
			if get_current_action_type() == ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
				if task_clock.is_stopped():
					return TASK_STATUSES.COMPLETE
				else:
					return TASK_STATUSES.ONGOING
			return TASK_STATUSES.FAILED
	return TASK_STATUSES.FAILED

func switch_task(override_task = null) -> int:
	var new_task = super(override_task)
	
	play_points.clear()
	var random_rotation : float = deg_to_rad(global_data.get_randf(0.0, 360.0))
	
	set_action_type(ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE, null)
	# EVERYTHING is updated in advance since these creatures NEED to be dynamic!
	match new_task:
		TASKS.RECHARGE:
			#set_action_type(ACTION_TYPES.NONE, null)
			pass
		TASKS.MOVE_TO_PLAY:
			pass
		TASKS.PLAY_A:
			task_clock.start(10.0)
			const sample_count := 21
			var x_values: Array = []
			x_values.resize(sample_count)
			for index in x_values.size():
				x_values.set(index, (-roundi(sample_count / 2) + index))
			var m: float = global_data.get_randf(0.05, 1.0)
			for x in x_values:
				var y: float = m * pow(x, 2) - personality_data.get(personality).get("min_distance") #y = mx^2 + b
				play_points.append(Vector2(x, y).rotated(random_rotation))
		TASKS.PLAY_B:
			task_clock.start(10.0)
			var spin_count: int = global_data.get_randi(1, 10)
			const sample_count := 21
			for i in spin_count:
				for s in sample_count:
					var rad_theta = deg_to_rad((360 / sample_count) * s)
					var x = get_min_distance() * cos(rad_theta)
					var y = get_min_distance() * sin(rad_theta)
					play_points.append(Vector2(x, y))
		TASKS.PLAY_C:
			task_clock.start(10.0)
			var spin_count: int = global_data.get_randi(1, 5)
			const sample_count := 42
			var gain_samples: Array[int] = []
			for s in sample_count:
				if gain_samples.has(s-1):
					if randf() > 0.25:
						gain_samples.append(s)
				elif randf() < 0.25:
					gain_samples.append(s)
			for i in spin_count:
				for s in sample_count:
					var temporary_gain: float = 0.0
					if gain_samples.has(s):
						temporary_gain += get_min_distance() / 2
					var rad_theta = deg_to_rad((360 / sample_count) * s)
					var x = (get_min_distance() + temporary_gain) * cos(rad_theta)
					var y = (get_min_distance() + temporary_gain) * sin(rad_theta)
					play_points.append(Vector2(x, y))
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
					play_points.append(Vector2(x, y))
		TASKS.PLAY_E:
			task_clock.start(10.0)
			
			
			
			
			
		TASKS.MOVE_TO_ORBIT:
			cached_target_position = Vector2(0, 50)
		TASKS.ORBIT:
			cached_target_position = position
		
		
		
		
		
		
		
	
	
	metadata["_current_task"] = TASKS.find_key(current_task)
	return new_task







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
	var adj_distance: float = move_toward(base_distance, sys_max_orbit_distance * 0.5, current_energy_index)
	return adj_distance

func get_min_distance() -> float:
	return personality_data.get(personality).get("min_distance")

func _on_energy_low() -> void:
	if current_task != TASKS.RECHARGE:
		if not cooldown_clock.is_stopped():
			await cooldown_clock.time_expired
			switch_task(TASKS.RECHARGE)
		else:
			switch_task(TASKS.RECHARGE)
	pass
