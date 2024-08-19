extends ItemList

signal playSavedAudioProfile(helper: audioProfileHelper)
signal removeSavedAudioProfile(helper: audioProfileHelper)

@onready var confirmed = load("res://Graphics/Misc/confirm_no_shadow.png")
@onready var denied = load("res://Graphics/Misc/denied.png")
@onready var icon = load("res://Graphics/play_icon.png")

enum METADATA_TYPE {PLAY, DELETE}

func initialize(helpers: Array[audioProfileHelper]):
	clear()
	
	for helper in helpers:
		add_item(helper.body.display_name, null, false)
		if helper.get_variation_class():
			match helper.is_guessed_variation_correct():
				true:
					add_item(str(variation_to_string(helper.body.get_guessed_variation()), " ", helper.get_variation_class().to_upper().replace("_", " ")), confirmed, false)
				false:
					add_item(str(variation_to_string(helper.body.get_guessed_variation()), " ", helper.get_variation_class().to_upper().replace("_", " ")), denied, false)
		else:
			match helper.is_guessed_variation_correct():
				true:
					add_item(variation_to_string(helper.body.get_guessed_variation()), confirmed, false)
				false:
					add_item(variation_to_string(helper.body.get_guessed_variation()), denied, false)
		
		var play_item = add_item("PLAY", icon, true)
		set_item_metadata(play_item, [helper, METADATA_TYPE.PLAY])
		
		var delete_item = add_item("DELETE", denied, true)
		set_item_metadata(delete_item, [helper, METADATA_TYPE.DELETE])
	pass

func variation_to_string(variation: bodyAPI.VARIATIONS):
	match variation:
		bodyAPI.VARIATIONS.LOW:
			return "LOW"
		bodyAPI.VARIATIONS.MEDIUM:
			return "MEDIUM"
		bodyAPI.VARIATIONS.HIGH:
			return "HIGH"
		_:
			return ""

func _on_item_clicked(index, _at_position, mouse_button_index):
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		var metadata = get_item_metadata(index)
		if metadata:
			match metadata.back():
				METADATA_TYPE.PLAY:
					emit_signal("playSavedAudioProfile", metadata.front())
				METADATA_TYPE.DELETE:
					emit_signal("removeSavedAudioProfile", metadata.front())
	pass
