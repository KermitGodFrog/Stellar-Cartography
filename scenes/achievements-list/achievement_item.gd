extends PanelContainer

@onready var name_label = $achievement_scroll/info_scroll/name_label #'achievement name' beca
@onready var description_label = $achievement_scroll/info_scroll/description
@onready var icon_texture = $achievement_scroll/icon

func initialize(achievement_name: String, achievement_description: String, achievement_icon = null):
	name_label.set_text(achievement_name)
	description_label.set_text(achievement_description)
	if achievement_icon != null:
		icon_texture.set_texture(achievement_icon) # will need to add icon support in achievements_popup.gd at some point!
	pass
