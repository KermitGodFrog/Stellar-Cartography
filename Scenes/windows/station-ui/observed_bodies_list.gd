extends ItemList

signal saveAudioProfile(helper: audioProfileHelper)
signal _addPlayerValue(amount: int)
signal finishedButtonPressed

@onready var confirmed = preload("uid://c5r5ok7jmth3o")
@onready var denied = preload("uid://cudxvqxk513ea")
@onready var icon = preload("uid://c5wk5giq8ua5h")

func initialize(helpers: Array[audioProfileHelper]):
	clear()
	
	for helper in helpers:
		helper.body.metadata["has_valid_audio_profile"] = false
		
		add_item(helper.body.get_display_name(), null, false)
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
			var value = helper.body.metadata.get("value")
			emit_signal("_addPlayerValue", value)
			add_item(str("(+", value, "n)"), null, false)
		if not helper.is_guessed_variation_correct():
			add_item("", null, false) #so columns dont get jumbled
		
		var save_item = add_item("SAVE", icon, true)
		set_item_metadata(save_item, helper)
	pass

func variation_to_string(variation: planetBodyAPI.VARIATIONS):
	match variation:
		planetBodyAPI.VARIATIONS.LOW:
			return "LOW"
		planetBodyAPI.VARIATIONS.MEDIUM:
			return "MEDIUM"
		planetBodyAPI.VARIATIONS.HIGH:
			return "HIGH"
		_:
			return ""

func _on_item_clicked(index, _at_position, mouse_button_index):
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		var metadata = get_item_metadata(index)
		if metadata:
			set_item_disabled(index, true)
			set_item_custom_bg_color(index, Color("#c0f576"))
			emit_signal("saveAudioProfile", metadata)
	pass

func _on_finished_button_pressed():
	emit_signal("finishedButtonPressed")
	pass
