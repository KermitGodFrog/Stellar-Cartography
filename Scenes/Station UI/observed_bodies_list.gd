extends ItemList

signal saveAudioProfile(audio_profile: audioProfileHelper)

@onready var confirmed = load("res://Graphics/Misc/confirm.png")
@onready var denied = load("res://Graphics/Misc/denied.png")
@onready var download = load("res://Graphics/download_icon.png")

func initialize(helpers: Array[audioProfileHelper]):
	clear()
	
	for helper in helpers:
		add_item(helper.body.display_name, null, false)
		if helper.get_variation_class():
			add_item(str(variation_to_string(helper.body.get_guessed_variation()), " ", helper.get_variation_class()), null, false)
		else:
			add_item(variation_to_string(helper.body.get_guessed_variation()), null, false)
		
		if helper.is_guessed_variation_correct(): add_item("", confirmed, false)
		if not helper.is_guessed_variation_correct(): add_item("", denied, false)
		
		var download_item = add_item("", download, true)
		set_item_metadata(download_item, helper)
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

func _on_item_clicked(index, at_position, mouse_button_index):
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		set_item_disabled(index, true)
		set_item_custom_bg_color(index, Color.GREEN)
		var metadata = get_item_metadata(index)
		if metadata:
			emit_signal("saveAudioProfile", metadata)
	pass
