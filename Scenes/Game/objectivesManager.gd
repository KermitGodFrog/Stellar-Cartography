extends Node

var _pause_mode: game_data.PAUSE_MODES = game_data.PAUSE_MODES.NONE:
	set(value):
		_pause_mode = value
		_on_pause_mode_changed(value)
signal queuePauseMode(new_mode: game_data.PAUSE_MODES)
signal setPauseMode(new_mode: game_data.PAUSE_MODES)
func _on_pause_mode_changed(value):
	match value:
		game_data.PAUSE_MODES.PAUSE_MENU:
			update_objectives_panel()
	pass

signal objectivesUpdated
signal updateObjectivesPanel(_parsed_objectives: Dictionary)
signal updateWorldObjectives(_objectives: Array[objectiveAPI])

var objectives: Array[objectiveAPI] = [] 

const MAX_TIME: float = 100.0

func _ready() -> void:
	objectivesUpdated.connect(_on_objectives_updated)
	startup_find_objectives() #TEMP - WHETHER TO FIND OR RECEIVE SHOULD BE DECIDED BY GAME
	pass

func _on_objectives_updated() -> void:
	update_world_objectives()
	pass

func startup_find_objectives() -> void: #called by game.gd when the game is NEW
	var paths = global_data.get_all_files("res://Data/objectives", "tres")
	for path in paths:
		var new_objective = load(path)
		var new_written_identifier = global_data.get_resource_name(new_objective)
		new_objective.written_identifier = new_written_identifier
		objectives.append(new_objective)
	pass

func startup_receive_objectives(_objectives: Array[objectiveAPI]) -> void: #called by game.gd when the game is LOADED
	objectives = _objectives
	pass


func _physics_process(delta: float) -> void:
	if _pause_mode == game_data.PAUSE_MODES.NONE:
		var pending = get_objectives_in_states([objectiveAPI.STATES.SUCCESS, objectiveAPI.STATES.FAILURE])
		for p in pending:
			p.increase_time(delta)
			if p.get_time() > MAX_TIME:
				p.set_state(objectiveAPI.STATES.INACTIVE)
	pass

func update_objectives_panel() -> void:
	var parsed: Dictionary = {}
	var reduced = get_objectives_in_states([objectiveAPI.STATES.ACTIVE, objectiveAPI.STATES.SUCCESS, objectiveAPI.STATES.FAILURE])
	for objective in reduced:
		parsed[objective.get_wid()] = objective
	emit_signal("updateObjectivesPanel", parsed)
	pass

func update_world_objectives() -> void:
	pass





func mark_category_active(category: String) -> void:
	set_category_state_with_sub_objectives(category, objectiveAPI.STATES.ACTIVE)
	pass

func mark_category_success(category: String) -> void:
	set_category_state_with_sub_objectives(category, objectiveAPI.STATES.SUCCESS)
	pass

func mark_category_failure(category: String) -> void:
	set_category_state_with_sub_objectives(category, objectiveAPI.STATES.FAILURE)
	pass




func get_objective(written_identifier: String) -> objectiveAPI:
	for o in objectives:
		if o.get_wid() == written_identifier:
			return o
	return null

func get_objectives_in_state(state: objectiveAPI.STATES) -> Array[objectiveAPI]:
	var state_objectives: Array[objectiveAPI] = []
	for o in objectives:
		if o.get_state() == state:
			state_objectives.append(o)
	return state_objectives

func get_objectives_in_states(states: Array[objectiveAPI.STATES]) -> Array[objectiveAPI]:
	var state_objectives: Array[objectiveAPI] = []
	for s in states:
		var all = get_objectives_in_state(s)
		state_objectives.append_array(all)
	return state_objectives

func get_objectives_in_category(category: String) -> Array[objectiveAPI]:
	var category_objectives: Array[objectiveAPI] = []
	for o in objectives:
		if o.categories.has(category):
			category_objectives.append(o)
	return category_objectives

func set_category_state(category: String, state: objectiveAPI.STATES) -> void:
	var category_objectives = get_objectives_in_category(category)
	for o in category_objectives:
		o.set_state(state)
	emit_signal("objectivesUpdated")
	pass

func set_category_state_with_sub_objectives(category: String, state: objectiveAPI.STATES) -> void:
	var category_objectives = get_objectives_in_category(category)
	for o in category_objectives:
		o.set_state(state)
		for wid in o.sub_objectives:
			var objective = get_objective(wid)
			if objective != null:
				objective.set_state(state)
	emit_signal("objectivesUpdated")
	pass
