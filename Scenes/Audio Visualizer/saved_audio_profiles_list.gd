extends "res://Scenes/Station UI/observed_bodies_list.gd"

@onready var play_icon = load("res://Graphics/play_icon.png")

func _ready():
	set_icon(play_icon)
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

func _on_item_clicked(index, at_position, mouse_button_index):
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		var metadata = get_item_metadata(index)
		if metadata:
			emit_signal("saveAudioProfileHelper", metadata)
	pass
