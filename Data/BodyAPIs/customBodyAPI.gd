extends bodyAPI
class_name customBodyAPI

##On interaction (theorised, orbiting, following), the game will set this as the value of the 'id' fact, if configured. Leave empty to let the game search for more complex queries derived from the body type.
@export var dialogue_tag: String:
	get = get_dialogue_tag, set = set_dialogue_tag

func get_dialogue_tag() -> String:
	return dialogue_tag
func set_dialogue_tag(value) -> void:
	dialogue_tag = value
	pass

@export var texture_path: String: #assumes that texture_path will always be set before post_texture_path, otherwise will override
	set(value):
		texture_path = value
		post_texture_path = value
@export var post_texture_path: String
@export var icon_path: String: #assumes that icon path will always be set before post_icon_path, otherwise will override
	set(value):
		icon_path = value
		post_icon_path = value
@export var post_icon_path: String
@export var mesh_path: String

func is_interaction_valid() -> bool:
	if (metadata.get("is_follow_available", true) == true) and (metadata.get("is_orbit_available", true) == true):
		return true
	return false
