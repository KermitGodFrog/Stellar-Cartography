extends Resource
class_name achievementsHelper
#such a high tech and complex class.. wow.. amazing :3

@export var achievement_wIDs: Dictionary

static func achievements_to_wIDs(_achievements: Dictionary) -> Dictionary:
	var wIDs: Dictionary = {}
	for a in _achievements:
		wIDs[global_data.get_resource_name(a)] = _achievements.get(a)
	return wIDs
