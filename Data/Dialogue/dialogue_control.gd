extends Control

@onready var image = $margin/panel/panel_margin/content_scroll/image
@onready var text = $margin/panel/panel_margin/content_scroll/text
@onready var options = $margin/panel/panel_margin/content_scroll/options
@onready var sfx = $sfx
@onready var music = $music

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
	text.push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
	#text.push_color(Color.RED)
	#text.append_text(str("\n \n", new_text))
	text.append_text("\n%s" % new_text)
	pass

func add_options(new_options: Dictionary):
	for new_option in new_options:
		var new_item_idx = options.add_item(new_option)
		var new_option_associated_rule = new_options.get(new_option, "defaultLeave")
		options.set_item_metadata(new_item_idx, new_option_associated_rule)
	pass

func set_image(path: String):
	var new = load("res://Graphics/Dialogue/%s" % path)
	if new:
		var texture = ImageTexture.create_from_image(new) #IMAGES MUST BE IMPORTED AS 'IMAGE' TYPE!
		image.set_texture(texture)
	pass

func clear_image() -> void:
	set_image("default.png")
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

func play_sound_effect(path: String):
	get_tree().call_group("audioHandler", "play_once", load("res://Sound/Dialogue/%s" % path), 0.0, "SFX")
	
	#var new = load("res://Sound/Dialogue/%s" % path)
	#if new:
		#sfx.stop()
		#sfx.set_stream(new)
		#sfx.play()
	pass

func _on_options_item_selected(index):
	text.push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
	text.push_color(Color.DARK_SLATE_BLUE)
	text.append_text("\n>>> %s" % options.get_item_text(index))
	text.pop_all()
	
	var new_query = responseQuery.new()
	new_query.add("concept", "optionSelected")
	new_query.add("option", options.get_item_metadata(index))
	clear_options() #options are always cleared in rules.csv when an option is selected anyway
	get_tree().call_group("dialogueManager", "speak", self, new_query)
	pass
