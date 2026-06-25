@tool
extends PanelContainer

@onready var title_label = $scroll/title_label
@onready var text_label = $scroll/text_label

@export var title: String
@export_multiline var text: String

func _ready() -> void:
	title_label.set_text(title)
	text_label.append_text(text)
	pass
