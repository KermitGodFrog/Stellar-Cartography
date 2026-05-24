extends PanelContainer

@onready var custom_tooltip = preload("uid://cer7wk3ixuyb6")
@export var tooltip_title: String

func _make_custom_tooltip(for_text):
	var custom_tooltip_instance = custom_tooltip.instantiate()
	custom_tooltip_instance.initialize(tooltip_title, for_text)
	return custom_tooltip_instance


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
