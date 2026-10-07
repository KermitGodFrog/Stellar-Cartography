extends Node

var achievements: Dictionary = {}
const default_achievements: Dictionary = {
	preload("uid://diwwcd4u152wj"): false,
	preload("uid://hwxe6ko2un15"): false,
	preload("uid://c1jawjdur6vwj"): false,
	preload("uid://b0njvlvfd51jw"): false,
	preload("uid://h11jp6ylt5p4"): false,
	preload("uid://bnnk3hpl5vyv5"): false,
	preload("uid://bs3s26w3bcouo"): false,
	preload("uid://cw60jj5x3nom5"): false,
	preload("uid://dtkpc2w8p3rlp"): false,
	preload("uid://b1p5pjreb7qtb"): false,
	preload("uid://dnqtbuyyvp4rp"): false,
	preload("uid://bmt6d3hv7bcuw"): false,
	preload("uid://ogjbkpajm27q"): false,
	preload("uid://2wykrp5tgsaf"): false
}

@onready var achievement_control = $achievement_display/achievement_control 

#func _process(_delta):
#	if Input.is_action_just_pressed("SC_DEBUG_OPEN_DEBUG_MENU"):
#		var unlock = achievements.keys().pick_random()
#		var _achievements = achievements.duplicate() # in case achievements is in a read-only state (like usual)
#		_achievements.set(unlock, true)
#		achievements = _achievements
#	pass

func _notification(what):
	match what:
		NOTIFICATION_PARENTED:
			#load achievements
			
			var helper: achievementsHelper = game_data.loadAchievements()
			if helper != null:
				print("HELPER EXISTS, LOADING")
				#convert written achievements to real achievements \/
				var _achievements: Dictionary = {}
				for a in default_achievements:
					var w_a = global_data.get_resource_name(a)
					if helper.written_achievements.has(w_a):
						_achievements[a] = helper.written_achievements.get(w_a)
				achievements = default_achievements.merged(_achievements, true)
			else:
				print("HELPER DOES NOT EXIST, RESETTING")
				achievements = default_achievements
			
			print("LOADING DONE")
		NOTIFICATION_WM_CLOSE_REQUEST:
			#save achievements
			
			var helper := achievementsHelper.new()
			var _written_achievements: Dictionary = {}
			for a in achievements:
				_written_achievements[global_data.get_resource_name(a)] = achievements.get(a)
			helper.written_achievements = _written_achievements
			game_data.saveAchievements(helper)
			
			print("SAVING DONE")
	pass

func _ready():
	global_data.scene_changed.connect(_on_scene_changed.unbind(1)) #>> unbind(1) = unbind 'path_to_scene'
	pass

func _on_scene_changed():
	var achievements_array: Array[responseAchievement] = []
	for a in achievements:
		achievements_array.append(a)
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
				var _achievements: Dictionary = achievements.duplicate() # in case achievements is in a read-only state (like usual)
				_achievements.set(a, true)
				achievements = _achievements
				print("UNLOCKED ACHIEVEMENT: ", a.name)
				achievement_control.queue_achievement(a)
			#else:
				#print("ACHIEVEMENT ALREADY UNLOCKED: ", a.name)
	pass
