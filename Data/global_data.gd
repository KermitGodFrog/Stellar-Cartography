extends Node

signal change_scene(path_to_scene)

func get_randi(from: int, to: int):
	return RandomNumberGenerator.new().randi_range(from, to)

func get_randf(from: float, to: float):
	return RandomNumberGenerator.new().randf_range(from, to)

func weighted_pick(dict: Dictionary, weight_key = null) -> Variant:
	var weights_sum := 0.0
	var keys = dict.keys()
	var weights = null
	if weight_key:
		for item_key in dict:
			weights_sum += dict[item_key][weight_key]
	else:
		weights = dict.values()
		for weight in weights:
			weights_sum += weight
	var remaining_distance := randf() * weights_sum
	for i in dict.size():
		if weight_key:
			remaining_distance -= dict[keys[i]][weight_key]
		else:
			remaining_distance -= weights[i]
		if remaining_distance < 0:
			return keys[i]
	return keys[0]

func get_all_files(path: String, file_ext := "", files := []):
	var dir = DirAccess.open(path)
	
	if DirAccess.get_open_error() == OK:
		dir.list_dir_begin()
		
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir():
				files = get_all_files(dir.get_current_dir() +"/"+ file_name, file_ext, files)
			else:
				if file_ext and file_name.get_extension() != file_ext:
					file_name = dir.get_next()
					continue
				
				files.append(dir.get_current_dir() +"/"+ file_name)
			
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access %s." % path)
	
	return files

var roman_numerals: Dictionary = {
	"1": "I",
	"2": "II",
	"3": "III",
	"4": "IV",
	"5": "V",
	"6": "VI",
	"7": "VII",
	"8": "VIII",
	"9": "IX",
	"10": "X",
	"11": "XI",
	"12": "XII",
	"13": "XIII",
	"14": "XIV",
	"15": "XV",
	"16": "XVI",
	"17": "XVII",
	"18": "XVIII",
	"19": "XIX",
	"20": "XX",
	"21": "XXI",
	"22": "XXII",
	"23": "XXIII",
	"24": "XXIV",
	"25": "XXV"
}

func convertToRomanNumeral(number: int):
	var conversion = roman_numerals.get(str(number))
	if conversion:
		return conversion
	else:
		return str(number)
