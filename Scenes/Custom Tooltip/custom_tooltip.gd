extends Control

@onready var tooltip_title = $tooltip_margin/tooltip_scroll/tooltip_title
@onready var tooltip_description = $tooltip_margin/tooltip_scroll/tooltip_text

func initialize(title: String, description: String):
	if not (tooltip_title and tooltip_description):
		await self.ready
	tooltip_title.set_text(title)
	tooltip_description.append_text(description)
	pass
