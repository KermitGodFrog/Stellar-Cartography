extends Button

@onready var custom_tooltip = preload("uid://cer7wk3ixuyb6")
@export var tooltip_title: String

func _make_custom_tooltip(for_text):
	var custom_tooltip_instance = custom_tooltip.instantiate()
	custom_tooltip_instance.initialize(tooltip_title, for_text)
	return custom_tooltip_instance
