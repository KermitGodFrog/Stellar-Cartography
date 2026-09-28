extends PanelContainer

@onready var name_label = $achievement_scroll/info_scroll/name_label #'achievement name' beca
@onready var description_label = $achievement_scroll/info_scroll/description
@onready var trophy_texture = $achievement_scroll/trophy

func initialize(achievement_name: String, achievement_description: String, display_hidden: bool = false, achievement_trophy = null):
	name_label.set_text(achievement_name)
	description_label.set_text(achievement_description)
	if achievement_trophy != null:
		trophy_texture.set_texture(achievement_trophy) # will need to add icon support in achievements_popup.gd at some point!
	if display_hidden:
		name_label.set_text("?".repeat(name_label.text.length()))
		description_label.set_text("?".repeat(description_label.text.length()))
	pass
