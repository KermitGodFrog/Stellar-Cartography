extends Label

const type_prefixes = {
	playerAPI.ACTION_TYPES.NONE: {true: "None", false: "None"},
	playerAPI.ACTION_TYPES.GO_TO: {true: "Going to", false: "Following"},
	playerAPI.ACTION_TYPES.ORBIT: {true: "Moving to orbit", false: "Orbiting"}
}

var _player_position_matrix: Array = [Vector2(0,0), Vector2(0,0)]

var current_text: String = String()

var prev_body: bodyAPI = null
var prev_type: playerAPI.ACTION_TYPES = playerAPI.ACTION_TYPES.NONE


func _physics_process(_delta: float) -> void:
	if (prev_type != playerAPI.ACTION_TYPES.NONE) and (prev_body != null):
		var body_distance = _player_position_matrix[0].distance_to(prev_body.position)
		set_text("%s (%.fR%c)" % [current_text, body_distance, "☉"])
	else:
		set_text(current_text)
	pass

func update(type: playerAPI.ACTION_TYPES, body: bodyAPI, pending: bool) -> void:
	var scenarios = type_prefixes.get(type)
	var prefix = scenarios.get(pending)
	var supplementary = String()
	if body != null: supplementary = body.get_display_name()
	current_text = "%s %s" % [prefix, supplementary]
	
	prev_body = body
	prev_type = type
	pass
