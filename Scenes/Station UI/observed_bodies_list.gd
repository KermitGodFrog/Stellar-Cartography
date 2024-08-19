extends ItemList

signal saveAudioProfile(helper: audioProfileHelper)

@onready var confirmed = load("res://Graphics/Misc/confirm_no_shadow.png")
@onready var denied = load("res://Graphics/Misc/denied.png")
@onready var icon = load("res://Graphics/download_icon.png")

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
		
		if helper.is_guessed_variation_correct():
			var added_value: int
			var value = helper.body.metadata.get("value")
			if value: added_value = value
			add_item(str("(+", added_value, "c)"), null, false)
		if not helper.is_guessed_variation_correct():
			add_item("", null, false) #so columns dont get jumbled
		
		var save_item = add_item("SAVE", icon, true)
		set_item_metadata(save_item, helper)
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
			set_item_disabled(index, true)
			set_item_custom_bg_color(index, Color8(0,30,0))
			emit_signal("saveAudioProfile", metadata)
	pass
