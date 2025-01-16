extends Node
#responsible for: loading and saving achievement data, telling achievement_control to flash when an achievement is unlocked (with info) and, of course, unlocking achievements when criteria is met

signal achievementsChanged(new_achievements: Array[achievement])

@export var achievements: Array[achievement] = []

func _ready():
	#load achievement data (global to all worlds) - names, descriptions, criteria and whether unlocked
	
	
	
	
	
	
	
	
	#it took me 1+ hour to figure out that i have to call_deferred this so it doesnt emit before the signal is connected to game.gd
	call_deferred("emit_signal", "achievementsChanged", achievements) #setup like this in case i want to add a hotkey to soft reload the game at runtime, to insta update the achievements list!
	pass

func receive_ranked_achievements(ranked_achievements: Dictionary):
	print("RANKED ACHIEVEMENTS ", ranked_achievements)
	
	for a: achievement in ranked_achievements:
		if ranked_achievements.get(a) == a.dialogue_criteria.size():
			#if number of matches == size of criteria:
			pass
	pass
