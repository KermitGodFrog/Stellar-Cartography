extends Node

var objectives: Dictionary = {} # {"objective name in filesystem (written identifier)": objectiveAPI}

func _ready() -> void:
	startup_find_objectives() #TEMP, THIS CLASS SHOULD NOT HAVE _ready() FUNCTION
	pass



func startup_find_objectives() -> void: #called by game.gd when the game is NEW
	#search the file system for objectives and add them to the dictionary with correct formatting
	
	var paths = global_data.get_all_files("res://Data/objectives", "tres")
	for path in paths:
		var new_objective = load(path)
		var written_identifier = global_data.get_resource_name(new_objective)
		objectives[written_identifier] = new_objective
	
	
	#works
	
	
	pass

func startup_receive_objectives(_objectives: Dictionary) -> void: #called by game.gd when the game is LOADED
	objectives = _objectives
	pass
