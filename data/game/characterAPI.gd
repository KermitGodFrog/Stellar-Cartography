extends Resource
class_name characterAPI

@export var display_name: String:
	get = get_display_name, set = set_display_name
func get_display_name() -> String:
	return display_name
func set_display_name(value: String) -> void:
	display_name = value
	pass

@export var alive: bool = true:
	get = is_alive
func is_alive() -> bool:
	return alive
func kill() -> void:
	alive = false
func resurrect() -> void:
	alive = true

@export var standing: int = 50:
	get = get_standing
func get_standing() -> int:
	return standing
func addStanding(amount : int) -> void:
	standing = mini(100, standing + amount)
	pass
func removeStanding(amount : int) -> void:
	standing = maxi(-100, standing - amount)
	pass

enum GENDERS {M, F, O}
@export var current_gender: GENDERS:
	get = get_gender, set = set_gender
func get_gender() -> GENDERS:
	return current_gender
func set_gender(value: GENDERS) -> void:
	current_gender = value

enum OCCUPATIONS {FIRST_OFFICER, CHIEF_ENGINEER, SECURITY_OFFICER, MEDICAL_OFFICER}
@export var current_occupation: OCCUPATIONS:
	get = get_occupation, set = set_occupation
func get_occupation() -> OCCUPATIONS:
	return current_occupation
func set_occupation(value: OCCUPATIONS) -> void:
	current_occupation = value
	pass



#func generateRandomWeighted(force_occupation: OCCUPATIONS) -> void: #DEPRECIATED
#	var entry: String = get_random_character_name_entry()
#	var entry_name = entry.get_slice(" : ", 0)
#	var entry_gender = entry.get_slice(" : ", 1)
#	
#	set_display_name(entry_name)
#	set_gender(entry_gender)
#	if force_occupation: set_occupation(force_occupation)
#	else: set_occupation(OCCUPATIONS.keys().pick_random())
#	pass

#func get_random_character_name_entry() -> String: #DEPRECIATED
#	var name_candidates: Array = []
#	var file = FileAccess.open("res://Data/Name Data/character_names.txt", FileAccess.READ)
#	while not file.eof_reached():
#		var line = file.get_line()
#		if not line.is_empty():
#			name_candidates.append(line)
#	file.close()
#	return name_candidates.pick_random()
