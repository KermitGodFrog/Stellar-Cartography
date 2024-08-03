extends Control

@onready var image = $margin/panel/panel_margin/content_scroll/image
@onready var text = $margin/panel/panel_margin/content_scroll/text
@onready var options = $margin/panel/panel_margin/content_scroll/options

func initialize(new_text, new_options):
	if new_text is String:
		text.set_text(new_text)
	
	options.clear()
	
	if new_options is Dictionary:
		for new_option in new_options:
			var new_item_idx = options.add_item(new_option)
			var new_option_associated_rule = new_options.get(new_option, "defaultLeave")
			options.set_item_metadata(new_item_idx, new_option_associated_rule)
	
	#does not have image or sound support yet
	pass

func add_text(new_text: String):
	text.append_text(str("\n", new_text))
	pass

func add_options(new_options: Dictionary):
	for new_option in new_options:
		var new_item_idx = options.add_item(new_option)
		var new_option_associated_rule = new_options.get(new_option, "defaultLeave")
		options.set_item_metadata(new_item_idx, new_option_associated_rule)
	pass

func clear_all():
	text.clear()
	options.clear()
	pass

func clear_text():
	text.clear()
	pass

func clear_options():
	options.clear()
	pass



func _on_options_item_selected(index):
	var new_query = responseQuery.new()
	new_query.add("concept", "optionSelected")
	new_query.add("option", options.get_item_metadata(index))
	get_tree().call_group("dialogueManager", "speak", self, new_query)
	pass
