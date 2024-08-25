extends Resource
class_name characterAPI

@export var display_name: String

func get_display_name():
	return display_name

func set_display_name(new_display_name: String) -> void:
	display_name = new_display_name
	pass

@export var is_alive: bool = true

enum GENDERS {M, F, O}
@export var current_gender: GENDERS

enum OCCUPATIONS {FIRST_OFFICER, CHIEF_ENGINEER, SECURITY_OFFICER, MEDICAL_OFFICER, LINGUIST, HISTORIAN}
@export var current_occupation: OCCUPATIONS

func get_gender():
	return current_gender

func set_gender(new_gender: GENDERS) -> void:
	current_gender = new_gender

func get_occupation():
	return current_occupation

func set_occupation(new_occupation: OCCUPATIONS) -> void:
	current_occupation = new_occupation
	pass

func generateRandomWeighted(force_occupation: OCCUPATIONS) -> void:
	var entry: String = get_random_character_name_entry()
	var entry_name = entry.get_slice(" : ", 0)
	var entry_gender = entry.get_slice(" : ", 1)
	
	set_display_name(entry_name)
	set_gender(entry_gender)
	if force_occupation: set_occupation(force_occupation)
	else: set_occupation(OCCUPATIONS.keys().pick_random())
	pass

func get_random_character_name_entry() -> String:
	var name_candidates: Array = []
	var file = FileAccess.open("res://Data/Name Data/character_names.txt", FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line()
		if not line.is_empty():
			name_candidates.append(line)
	file.close()
	return name_candidates.pick_random()
