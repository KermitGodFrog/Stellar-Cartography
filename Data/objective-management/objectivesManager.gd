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
			emit_signal("updateObjectivesPanel", active_objectives)
	pass

signal activeObjectivesChanged(_active_objectives: Array[objectiveAPI])
signal updateObjectivesPanel(_active_objectives: Array[objectiveAPI])

var bank_objectives: Dictionary = {} # {wID: path}
var bank_categories: Dictionary = {} # {wID: path}

var active_objectives: Array[objectiveAPI] = []:
	set(value):
		active_objectives = value
		print("ACTIVE OBJECTIVES CHANGED")
		print(active_objectives)

func _ready() -> void:
	start_construct_banks() 
	pass

func start_construct_banks() -> void: #called by game.gd when the game is NEW
	var objective_paths = global_data.get_all_files("res://Data/objective-management/objectives", "tres")
	for path: String in objective_paths:
		var wID = path.get_file().trim_suffix(".tres")
		bank_objectives[wID] = path
	var category_paths = global_data.get_all_files("res://Data/objective-management/categories", "tres")
	for path: String in category_paths:
		var wID = path.get_file().trim_suffix(".tres")
		bank_categories[wID] = path
	pass

func start_receive_active_objectives(_active_objectives: Array[objectiveAPI]) -> void: #called by game.gd when the game is LOADED
	print("ACTIVE OBJECTIVES RECEIVED FROM GAME AT STARTUP")
	for i in _active_objectives:
		print("wID: ", i.get_wID())
		print("STATE: ", i.get_state())
		print("TIME: ", i.get_time())
		print("TITLE: ", i.title)
		print("DESCRIPTION: ", i.description)
	active_objectives = _active_objectives
	pass





func mark_objective(wID: String, state: objectiveAPI.STATES) -> void:
	var o = get_objective(wID)
	if o != null:
		o.set_state(state)
	emit_signal("activeObjectivesChanged", active_objectives)
	pass

func mark_category(wID: String, state: objectiveAPI.STATES) -> void:
	var c = load_category(wID)
	if c != null:
		var objective_wIDs = c.objective_wIDs
		for o_wID in objective_wIDs:
			mark_objective(o_wID, state)
	emit_signal("activeObjectivesChanged", active_objectives)
	pass

func clear_objective_if_applicable(wID: String) -> void:
	for o in active_objectives:
		if o.get_wID() == wID:
			active_objectives.erase(o)
	emit_signal("activeObjectivesChanged", active_objectives)
	pass

func clear_category_if_applicable(wID: String) -> void:
	var c = load_category(wID)
	if c != null:
		var objective_wIDs = c.objective_wIDs
		for o_wID in objective_wIDs:
			clear_objective_if_applicable(o_wID)
	emit_signal("activeObjectivesChanged", active_objectives)
	pass






func get_objective(wID: String) -> objectiveAPI:
	for o in active_objectives:
		if o.get_wID() == wID:
			return o
	var new = load_objective(wID)
	active_objectives.append(new)
	return new

func load_objective(wID: String) -> objectiveAPI:
	var path = bank_objectives.get(wID)
	if path != null:
		var new = load(path)
		new.set_wID(wID)
		return new
	return null

func load_category(wID: String) -> categoryAPI:
	var path = bank_categories.get(wID)
	if path != null:
		var new = load(path)
		new.set_wID(wID)
		return new
	return null


func get_active_objectives_in_states(states: Array[objectiveAPI.STATES]) -> Array:
	var valid: Array = []
	for o in active_objectives:
		for s in states:
			if o.get_state() == s:
				valid.append(o)
	return valid
