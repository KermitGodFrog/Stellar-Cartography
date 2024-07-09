extends "res://Scenes/Station UI/observed_bodies_list.gd"

@onready var play_icon = load("res://Graphics/play_icon.png")

func _ready():
	set_icon(play_icon)
	pass

func _on_item_clicked(index, at_position, mouse_button_index):
	if mouse_button_index == MOUSE_BUTTON_LEFT:
		var metadata = get_item_metadata(index)
		if metadata:
			emit_signal("saveAudioProfileHelper", metadata)
	pass
