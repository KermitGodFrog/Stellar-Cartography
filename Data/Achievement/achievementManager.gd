extends Node
#responsible for: loading and saving achievement data, telling achievement_control to flash when an achievement is unlocked (with info) and, of course, unlocking achievements when criteria is met

signal achievementsChanged(new_achievements: Array[achievement])

var achievements: Array[achievement] = []

func _ready():
	#load achievement data (global to all worlds) - names, descriptions, criteria and whether unlocked
	var helper = game_data.loadAchievements()
	if helper != null:
		achievements = helper.achievements
	else:
		for a in game_data.DEFAULT_ACHIEVEMENTS:
			achievements.append(a.duplicate())
	
	#unlike settings or the world, achievement data must be accessible anywhere at any time!
	#rather then saving and loading the data in all parts of the game whenever necessary, the achievement data will simply be LOADED on game start, and SAVED on game exit.
	#after loading achievement data, it will be sent to a game_data.gd variable. this data is modified at runtime (for whether achievements are unlocked or not) and is only saved when exiting the game
	
	
	
	
	
	
	#it took me 1+ hour to figure out that i have to call_deferred this so it doesnt emit before the signal is connected to game.gd
	call_deferred("emit_signal", "achievementsChanged", achievements) #setup like this in case i want to add a hotkey to soft reload the game at runtime, to insta update the achievements list!
	pass

func receive_ranked_achievements(ranked_achievements: Dictionary):
	print("RANKED ACHIEVEMENTS ", ranked_achievements)
	
	for a: achievement in ranked_achievements:
		if ranked_achievements.get(a) == a.dialogue_criteria.size():
			#if number of matches == size of criteria:
			
			#then, if achievement not already unlocked :3 :
			#>unlock achievement
			pass
	pass
