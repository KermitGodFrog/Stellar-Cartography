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
#	"tutorial1_1": [], #mark the nearby body with the ping button ::: dont copy/paste words - keywords will probably allow the player to take info from their STM
#	"tutorial1_2": [], #OPTIONAL test the central board. (objective never successful, use italics)
#	"tutorial2_1": [], # orbit the body
#	"tutorial2_2": [] #OPTIONAL zoom up/down using the scopes
}
#construct in objective-management/objectives ^^^

var bank_categories: Dictionary = {} #wID: [objective_wIDs]
#construct in objective-management/categories ^^^

var active_objectives: Array[objectiveAPI] = []

func _ready() -> void:
	start_construct_banks()
	pass

func start_construct_banks() -> void: #called by game.gd when the game is NEW
	var objective_paths = global_data.get_all_files("res://Data/objective-management/objectives", "tres")
	for path: String in objective_paths:
		var wID = path.get_file().trim_suffix(".tres")
		var objective: objectiveAPI = load(path)
		bank_objectives[wID] = [objective.title, objective.description]
	var category_paths = global_data.get_all_files("res://Data/objective-management/categories", "tres")
	for path: String in category_paths:
		var wID = path.get_file().trim_suffix(".tres")
		var category: categoryAPI = load(path)
		bank_categories[wID] = category.objective_wIDs
	pass

func start_receive_active_objectives(_active_objectives: Array[objectiveAPI]) -> void: #called by game.gd when the game is LOADED
	active_objectives.append_array(_active_objectives)
	pass





func mark_objective(wID: String, state: objectiveAPI.STATES) -> void:
	var o = get_objective(wID, state == objectiveAPI.STATES.NONE)
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






func get_objective(wID: String, loading_allowed: bool) -> objectiveAPI:
	for o in active_objectives:
		if o.get_wID() == wID:
			return o
	if loading_allowed:
		var new = load_objective(wID)
		active_objectives.append(new)
		return new
	return null

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

func get_active_objectives_in_states(states: Array[objectiveAPI.STATES]) -> Array:
	var valid: Array = []
	for o in active_objectives:
		for s in states:
			if o.get_state() == s:
				valid.append(o)
	return valid
