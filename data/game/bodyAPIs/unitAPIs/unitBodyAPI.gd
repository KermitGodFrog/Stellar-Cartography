extends bodyAPI
class_name unitBodyAPI
#note that for some stupid fuckin reason, if set_action_type is not set when added, it wont move? stupid thing. stupid stupid stupid.

signal orbitingBody(body: bodyAPI)
signal followingBody(body: bodyAPI)
signal actionTypePendingOrCompleted(_type: ACTION_TYPES, _body: bodyAPI, _pending: bool)

signal boosting_changed(new_value: bool)

#this is a kinda hacky hack class that the game interprets differently to the normal bodyAPI inherited classes
#it doesnt orbit - it has a target position and moves towards it depending on its internal speed
#these are also drawn differently by system_map

@export var speed: int
func get_adjusted_speed() -> int:
	if boosting:
		return speed * 5 * (1 + (-int(in_asteroid_belt) * 0.5))
	else:
		return speed * (1 + (-int(in_asteroid_belt) * 0.5))

var boosting: bool = false:
	set(value):
		if not boosting == value:
			emit_signal("boosting_changed", value)
		boosting = value
var in_asteroid_belt: bool = false
var in_pulsar_beam: bool = false

var rotation_hint: float #used for orbiting mechanics
@export_storage var target_position: Vector2
enum ACTION_TYPES {NONE, GO_TO, ORBIT, NONE_SLOWDOWN_OVERRIDE}
@export_storage var current_action_type: ACTION_TYPES = ACTION_TYPES.NONE
@export_storage var pending_action_body : bodyAPI:
	set(value):
		pending_action_body = value
		emit_signal("actionTypePendingOrCompleted", current_action_type, pending_action_body, true)
@export_storage var action_body : bodyAPI:
	set(value):
		action_body = value
		emit_signal("actionTypePendingOrCompleted", current_action_type, action_body, false)

#core movement methods

func updatePosition(delta) -> void:
	rotation_hint += delta
	if pending_action_body:
		match current_action_type:
			ACTION_TYPES.NONE:
				if not position.distance_to(target_position) < get_adjusted_speed():
					position += position.direction_to(target_position) * get_adjusted_speed() * delta
				else:
					position += position.direction_to(target_position) * position.distance_to(target_position) * delta
			ACTION_TYPES.GO_TO:
				var pos = pending_action_body.position
				if not position.distance_to(pos) < (pending_action_body.radius):
					position += position.direction_to(pos) * get_adjusted_speed() * delta
				else:
					position = pos
				target_position = pos
			ACTION_TYPES.ORBIT:
				var pos = get_orbit_position_for_body(pending_action_body)
				if not position.distance_to(pos) < (pending_action_body.radius):
					position += position.direction_to(pos) * get_adjusted_speed() * delta
				else:
					position = pos
				target_position = pos
	elif action_body:
		match current_action_type:
			ACTION_TYPES.NONE:
				if not position.distance_to(target_position) < get_adjusted_speed():
					position += position.direction_to(target_position) * get_adjusted_speed() * delta
				else:
					position += position.direction_to(target_position) * position.distance_to(target_position) * delta
			ACTION_TYPES.GO_TO:
				var pos = action_body.position
				position = pos
				target_position = pos 
			ACTION_TYPES.ORBIT:
				var dir = Vector2.UP.rotated(rotation_hint)
				var pos = action_body.position
				pos = pos + (dir * ((3 * action_body.radius) + 1.0))
				position = pos
				target_position = pos
	elif current_action_type == ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
		if not position.distance_to(target_position) < (get_adjusted_speed() * delta):
			position += position.direction_to(target_position) * get_adjusted_speed() * delta
		else:
			position = target_position
	else:
		if not position.distance_to(target_position) < get_adjusted_speed():
			position += position.direction_to(target_position) * get_adjusted_speed() * delta
		else:
			position += position.direction_to(target_position) * position.distance_to(target_position) * delta
	pass

func updateActionBodyState() -> void:
	if pending_action_body:
		match current_action_type:
			ACTION_TYPES.NONE:
				pending_action_body = null
				action_body = null
			ACTION_TYPES.GO_TO:
				var pos = pending_action_body.position
				if position.distance_to(pos) < (pending_action_body.radius + 1.0):
					emit_signal("followingBody", pending_action_body)
					var temp = pending_action_body
					pending_action_body = null
					action_body = temp
			ACTION_TYPES.ORBIT:
				var pos = get_orbit_position_for_body(pending_action_body)
				if position.distance_to(pos) < (pending_action_body.radius + 1.0):
					emit_signal("orbitingBody", pending_action_body)
					var temp = pending_action_body 
					pending_action_body = null
					action_body = temp
			ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
				pending_action_body = null
				action_body = null
	elif action_body:
		match current_action_type:
			ACTION_TYPES.NONE:
				pending_action_body = null
				action_body = null
			ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
				pending_action_body = null
				action_body = null
	else: 
		match current_action_type:
			ACTION_TYPES.NONE:
				pending_action_body = null
				action_body = null
			ACTION_TYPES.NONE_SLOWDOWN_OVERRIDE:
				pending_action_body = null
				action_body = null
	pass

func set_action_type(type: ACTION_TYPES, new_body: bodyAPI) -> void:
	current_action_type = type
	if new_body != null:
		pending_action_body = new_body
	pass

func orbit_body(b: orbitBodyAPI) -> void:
	set_action_type(ACTION_TYPES.ORBIT, b)
	pass

func go_to_body(b: bodyAPI) -> void:
	set_action_type(ACTION_TYPES.GO_TO, b)
	pass

func course_to_position(pos: Vector2) -> void:
	set_action_type(ACTION_TYPES.NONE, null)
	target_position = pos
	pass

#miscellaneous getters and appraisals

func get_orbit_position_for_body(body: bodyAPI) -> Vector2:
	var dir = Vector2.UP.rotated(rotation_hint)
	var orbit_pos = body.position
	orbit_pos = orbit_pos + (dir * ((3 * body.radius) + 1.0))
	return orbit_pos

func get_current_action_type() -> ACTION_TYPES:
	return current_action_type

func get_relevant_action_body() -> bodyAPI:
	if current_action_type != ACTION_TYPES.NONE:
		var pending = is_action_pending()
		match pending:
			true:
				return pending_action_body
			false:
				return action_body
	return null

func is_action_pending() -> bool:
	if pending_action_body != null:
		return true
	elif action_body != null:
		return false
	return false
