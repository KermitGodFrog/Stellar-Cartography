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

var bank_objectives: Dictionary = { #wID: [title, description] (so its quick)
	"test1": ["Test 1", "jeeble"],
	"test2": ["Test 2", "gooble"]
}

var bank_categories: Dictionary = { #wID: [objective_wIDs]
	"test_category": ["test1", "test2"]
}

var active_objectives: Array[objectiveAPI] = []:
	set(value):
		active_objectives = value
		print("ACTIVE OBJECTIVES CHANGED: ", active_objectives)

func start_receive_active_objectives(_active_objectives: Array[objectiveAPI]) -> void: #called by game.gd when the game is LOADED
	for i in _active_objectives:
		print("wID: ", i.get_wID())
		print("STATE: ", i.get_state())
		print("TITLE: ", i.title)
		print("DESCRIPTION: ", i.description)
	active_objectives.append_array(_active_objectives)
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
		var _objective_wIDs = c.objective_wIDs
		for o_wID in _objective_wIDs:
			mark_objective(o_wID, state)
	emit_signal("activeObjectivesChanged", active_objectives)
	pass

func clear_objective(wID: String) -> void:
	for o in active_objectives:
		if o.get_wID() == wID:
			active_objectives.erase(o)
	emit_signal("activeObjectivesChanged", active_objectives)
	pass

func clear_category(wID: String) -> void:
	var c = load_category(wID)
	if c != null:
		var _objective_wIDs = c.objective_wIDs
		for o_wID in _objective_wIDs:
			clear_objective(o_wID)
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
	var data = bank_objectives.get(wID) as PackedStringArray
	if data != null:
		var _title = data[0]
		var _description = data[1]
		
		var new = objectiveAPI.new()
		new.set_wID(wID)
		new.title = _title
		new.description = _description
		return new
	return null

func load_category(wID: String) -> categoryAPI:
	var _objective_wIDs = bank_categories.get(wID) as PackedStringArray
	if _objective_wIDs.size() > 0:
		var new = categoryAPI.new()
		new.set_wID(wID)
		new.objective_wIDs = _objective_wIDs
		return new
	return null
