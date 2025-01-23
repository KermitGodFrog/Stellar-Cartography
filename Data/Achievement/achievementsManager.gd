extends Node

var achievements: Dictionary = {}:
	set(value):
		achievements = value
		#print("ACHIEVEMENTS UPDATED ", value)
var achievements_array: Array[responseAchievement] = []:
	get:
		var array: Array[responseAchievement] = []
		for a in achievements:
			array.append(a)
		return array
const default_achievements: Dictionary = {
	preload("res://Data/Achievement/Achievements/optionSelectedTutorialWin.tres"): false,
	preload("res://Data/Achievement/Achievements/anyTutorialOmissionOrbitingPREV.tres"): false,
	preload("res://Data/Achievement/Achievements/playerWinOneMillionScore.tres"): false,
	preload("res://Data/Achievement/Achievements/playerWinTwoMillionScore.tres"): false,
	preload("res://Data/Achievement/Achievements/playerWinThreeMillionScore.tres"): false,
	preload("res://Data/Achievement/Achievements/playerWinAllCharactersAlive.tres"): false,
	preload("res://Data/Achievement/Achievements/anyAllModulesUnlocked.tres"): false,
	preload("res://Data/Achievement/Achievements/anyAudioVisualizerUnlocked.tres"): false,
	preload("res://Data/Achievement/Achievements/anyLongRangeScopesUnlocked.tres"): false,
	preload("res://Data/Achievement/Achievements/followingBodyWormholeInFrontier.tres"): false,
	preload("res://Data/Achievement/Achievements/followingBodyWormholeInAbyss.tres"): false,
	preload("res://Data/Achievement/Achievements/anyHullDeteriorationFifty.tres"): false,
	#preload("res://Data/Achievement/Achievements/anyIsWarCriminal.tres"): false
	#preload("res://Data/Achievement/Achievements/anyLRSAndAVUnlockedDEBUG.tres"): false
}

#/\/\/\/\/\
#The export version of the game MUST have a different QUANTITY of achievements than the previous version if it has been tampered with.
#If this doesnt happen, players with achievement data from previous versions will not see the changes.

@onready var achievement_control = $achievement_display/achievement_control #might be depreciated soon

func _process(_delta):
	#if Input.is_action_just_pressed("SC_DEBUG_MISC"):
		#achievements = default_achievements
	pass

func _notification(what):
	match what:
		NOTIFICATION_PARENTED:
			#load achievements
			var helper: achievementsHelper = await game_data.loadAchievements()
			if helper != null:
				print("HELPER EXISTS, LOADING")
				achievements = helper.achievements.duplicate(true)
			else:
				print("HELPER DOES NOT EXIST, RESETTING")
				achievements = default_achievements.duplicate(true)
			
			if achievements.size() != default_achievements.size():
				print("SIZE DIFFERENCE, ASSUMING GAME UPDATE, RESETTING (", achievements.size(), " VS ", default_achievements.size(), ")")
				achievements = default_achievements.duplicate(true)
			
			print("LOADING DONE")
		NOTIFICATION_WM_CLOSE_REQUEST:
			#save achievements
			
			var helper = achievementsHelper.new()
			helper.achievements = achievements
			game_data.saveAchievements(helper)
			
			print("SAVING DONE")
	pass

func _ready():
	global_data.scene_changed.connect(_on_scene_changed.unbind(1)) #i think this class is high enough level to be granted access to this
	#unbind(1) = unbind 'path_to_scene'
	pass

func _on_scene_changed():
	print("DISTRIBUTING UPDATED ACHIEVEMENTS")
	get_tree().call_deferred("call_group", "FOLLOW_ACHIEVEMENTS_ARRAY_UPDATE", "receive_updated_achievements_array", achievements_array) #this calls too early/late and doesnt work for some reason when/if achievementsHelper 'achievements' variable is inferred to be an array rather than an Array[achievement]
	get_tree().call_deferred("call_group", "FOLLOW_ACHIEVEMENTS_UPDATE", "receive_updated_achievements", achievements)
	pass

func receive_ranked_achievements(ranked_achievements: Dictionary):
	#print("RANKED ACHIEVEMENTS ", ranked_achievements)
	#for i in ranked_achievements:
		#print(i.name, " ", ranked_achievements.get(i))
	
	for a: responseAchievement in ranked_achievements:
		if ranked_achievements.get(a) == a.dialogue_criteria.size(): #e.g, if number of matches == size of criteria:
			if achievements.get(a) == false:
				achievements[a] = true
				print("UNLOCKED ACHIEVEMENT: ", a.name)
				achievement_control.queue_achievement(a)
				#needs to queue unlocked achievements
			#else:
				#print("ACHIEVEMENT ALREADY UNLOCKED: ", a.name)
	pass
