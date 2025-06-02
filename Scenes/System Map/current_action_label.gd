extends Label

const type_prefixes = {
	playerAPI.ACTION_TYPES.NONE: {true: "None", false: "None"},
	playerAPI.ACTION_TYPES.GO_TO: {true: "Going to", false: "Following"},
	playerAPI.ACTION_TYPES.ORBIT: {true: "Moving to orbit", false: "Orbiting"}
}

var _player_position_matrix: Array = [Vector2(0,0), Vector2(0,0)]

func update(type: playerAPI.ACTION_TYPES, body: bodyAPI, pending: bool):
	print("UPDATED")
	var scenarios = type_prefixes.get(type)
	var prefix = scenarios.get(pending)
	
	var supplementary = String()
	
	if body != null:
		var body_name = body.get_display_name()
		#var body_distance = _player_position_matrix[0].distance_to(body.position)
		#supplementary = "%s (%.f%c)" % [body_name, body_distance, "☉"]
		supplementary = body_name
		# ^^^ a tragedy... i didny want to run ts in physics process...
	
	var new_text = "%s %s" % [prefix, supplementary]
	
	set_text(new_text)
	pass
