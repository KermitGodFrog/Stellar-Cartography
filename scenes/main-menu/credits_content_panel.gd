@tool
extends PanelContainer

@onready var title_label = $scroll/title_label
@onready var text_label = $scroll/text_label

@export var title: String
@export_multiline var text: String
@export var panel_color: Color = Color("181818")

func _ready() -> void:
	title_label.set_text(title)
	text_label.append_text(text)
	set("theme_override_Styles/panel/bg_color", panel_color)
	pass
