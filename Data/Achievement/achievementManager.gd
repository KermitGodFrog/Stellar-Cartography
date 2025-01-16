extends Node
#responsible for: telling achievement_control to flash when an achievement is unlocked (with info) and, of course, unlocking achievements when criteria is met
#ironically, most things related to achievements are controlled by game_data.gd lol

#unlike settings or the world, achievement data must be accessible anywhere at any time!
#rather then saving and loading the data in all parts of the game whenever necessary, the achievement data will simply be LOADED on game start, and SAVED on game exit.
#after loading achievement data, it will be sent to a game_data.gd variable. this data is modified at runtime (for whether achievements are unlocked or not) and is only saved when exiting the game

@onready var achievement_control = $achievement_display/achievement_control

func receive_ranked_achievements(ranked_achievements: Dictionary):
	print("RANKED ACHIEVEMENTS ", ranked_achievements)
	
	for a: achievement in ranked_achievements:
		if ranked_achievements.get(a) == a.dialogue_criteria.size(): #e.g, if number of matches == size of criteria:
			if a.unlocked == false:
				a.unlocked = true
				print("UNLOCKED ACHIEVEMENT: ", a.name)
				achievement_control.blink(a.name, a.description)
			else:
				print("ACHIEVEMENT ALREADY UNLOCKED: ", a.name)
	pass
