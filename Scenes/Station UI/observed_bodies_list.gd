extends ItemList

signal saveAudioProfileHelper(helper: audioProfileHelper)

@onready var confirmed = load("res://Graphics/Misc/confirm.png")
@onready var denied = load("res://Graphics/Misc/denied.png")
@onready var icon = load("res://Graphics/download_icon.png")

func set_icon(resource):
	icon = resource
	pass

func initialize(helpers: Array[audioProfileHelper]):
	clear()
	
	for helper in helpers:
		add_item(helper.body.display_name, null, false)
		if helper.get_variation_class():
			add_item(str(variation_to_string(helper.body.get_guessed_variation()), " ", helper.get_variation_class().to_upper().replace("_", " ")), null, false)
		else:
			add_item(variation_to_string(helper.body.get_guessed_variation()), null, false)
		
		if helper.is_guessed_variation_correct(): add_item("", confirmed, false)
		if not helper.is_guessed_variation_correct(): add_item("", denied, false)
		
		var item = add_item("", icon, true)
		set_item_metadata(item, helper)
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
		var metadata = get_item_metadata(index)
		if metadata:
			set_item_disabled(index, true)
			set_item_custom_bg_color(index, Color.DARK_OLIVE_GREEN)
			emit_signal("saveAudioProfileHelper", metadata)
	pass
