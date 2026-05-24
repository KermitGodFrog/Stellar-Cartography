extends "res://scenes/system-map/custom_tooltip_control.gd"

@onready var title_label = $title_label
var associated_id
var data: Dictionary = {}

func _ready() -> void: #title, description, effect
	var title = data.get("title", "undefined")
	var description = data.get("description", "undefined")
	var effect = data.get("effect", "undefined")
	
	title_label.set_text(title)
	tooltip_title = title
	set_tooltip_text("[i]%s[/i]\n\n%s" % [description, effect])
	pass
