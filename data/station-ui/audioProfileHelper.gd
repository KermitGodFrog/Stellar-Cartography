extends Resource
class_name audioProfileHelper
#any value that is @export is saveable for future play sessions. constants shouldny be saved.

@export var mix: Array = [0,0,0,0]
@export var body: planetBodyAPI

#QUICK GET FOR STATION_UI AND AUDIO VISUALIZER \/\/\/\/

func is_guessed_variation_correct():
	if body.get_current_variation() and body.get_guessed_variation():
		if body.get_current_variation() == body.get_guessed_variation():
			return true
		else:
			return false
	else:
		return false

func get_variation_class():
	return starSystemAPI.new().planet_type_data.get(body.metadata.get("planet_type")).get("variation_class")
