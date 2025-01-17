extends Node
#responsible for: telling achievement_control to flash when an achievement is unlocked (with info) and, of course, unlocking achievements when criteria is met
#ironically, most things related to achievements are controlled by game_data.gd lol

#unlike settings or the world, achievement data must be accessible anywhere at any time!
#rather then saving and loading the data in all parts of the game whenever necessary, the achievement data will simply be LOADED on game start, and SAVED on game exit.
#after loading achievement data, it will be sent to a game_data.gd variable. this data is modified at runtime (for whether achievements are unlocked or not) and is only saved when exiting the game

#!!!
#all of above might be depreciated watch out /\/\/\/\
#!!!

var achievements: Array[achievement] = []:
	set(value):
		achievements = value
		print("ACHIEVEMENTS UPDATED ", value)
const default_achievements: Array[achievement] = [
	preload("res://Data/Achievement/Achievements/anyAllModulesUnlocked.tres"),
	preload("res://Data/Achievement/Achievements/anyAudioVisualizerUnlocked.tres"),
	preload("res://Data/Achievement/Achievements/anyHullDeteriorationFifty.tres"),
	preload("res://Data/Achievement/Achievements/anyIsWarCriminal.tres"),
	preload("res://Data/Achievement/Achievements/anyLongRangeScopesUnlocked.tres"),
	preload("res://Data/Achievement/Achievements/followingBodyWormholeInAbyss.tres"),
	preload("res://Data/Achievement/Achievements/followingBodyWormholeInFrontier.tres"),
	preload("res://Data/Achievement/Achievements/playerWinAllCharactersAlive.tres"),
	preload("res://Data/Achievement/Achievements/playerWinOneMillionScore.tres"),
	preload("res://Data/Achievement/Achievements/playerWinThreeMillionScore.tres"),
	preload("res://Data/Achievement/Achievements/playerWinTwoMillionScore.tres"),
	preload("res://Data/Achievement/Achievements/optionSelectedTutorialWin.tres")
]

@onready var achievement_control = $achievement_display/achievement_control #might be depreciated soon

func _process(_delta):
	#for a in achievements:
		#print(a.unlocked)
	pass

func _notification(what):
	match what:
		NOTIFICATION_PARENTED:
			#load achievements
			var helper: achievementsHelper = await game_data.loadAchievements()
			if helper != null:
				print("HELPER EXISTS, LOADING ACHIEVEMENTS")
				achievements = helper.achievements.duplicate(true)
			else:
				print("HELPER DOES NOT EXIST, RESETTING ACHIEVEMENTS")
				achievements = default_achievements.duplicate(true)
			
			if achievements.size() != default_achievements.size():
				print("SIZE DIFFERENCE, ASSUMING GAME UPDATE, RESETTING ACHIEVEMENTS")
				print(achievements.size(), " VS ", default_achievements.size())
				achievements = default_achievements.duplicate(true)
			
			print("LOADING DONE")
		NOTIFICATION_WM_CLOSE_REQUEST:
			#save achievements
			
			var helper = achievementsHelper.new()
			
			helper.achievements.append_array(achievements)
			
			game_data.saveAchievements(helper)
			
			print("SAVING DONE")
	pass

func _ready():
	global_data.change_scene.connect(_change_scene) #i think this class is high enough level to be granted access to this
	pass

func _change_scene(_path_to_scene, _with_init_type = null, _with_init_data = null):
	#maybe make a more general group to do this later, as other things will need updated achievements list (especially main menu display) :3
	print("SENDING UPDATED ACHIEVEMENTS")
	get_tree().call_deferred("call_group", "dialogueManager", "receive_updated_achievements", achievements) #this calls too early/late and doesnt work for some reason when/if achievementsHelper 'achievements' variable is inferred to be an array rather than an Array[achievement]
	pass



func receive_ranked_achievements(ranked_achievements: Dictionary):
	print("RANKED ACHIEVEMENTS ", ranked_achievements)
	#for i in ranked_achievements:
		#print(i.name, " ", ranked_achievements.get(i))
	
	for a: achievement in ranked_achievements:
		if ranked_achievements.get(a) == a.dialogue_criteria.size(): #e.g, if number of matches == size of criteria:
			if a.unlocked == false:
				a.unlocked = true
				print("UNLOCKED ACHIEVEMENT: ", a.name)
				achievement_control.blink(a.name, a.description) #might be depreciated soon
				#needs to queue unlocked achievements
			else:
				print("ACHIEVEMENT ALREADY UNLOCKED: ", a.name)
	pass
