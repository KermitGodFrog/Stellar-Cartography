extends Control

@onready var image = $margin/panel/panel_margin/content_scroll/image
@onready var text = $margin/panel/panel_margin/content_scroll/text
@onready var options_scroll = $margin/panel/panel_margin/content_scroll/options_scroll
@onready var sfx = $sfx
@onready var music = $music
@onready var option = preload("res://Data/Dialogue/dialogue_option.tscn")

const TYPING_SPEED: int = 350.0 #could have this in settings! good test for a slider option!
var typing_position: float = 0.0
var options_added: int = 0 #added since last clear
func _process(delta):
	typing_position = clampf(typing_position + (delta * TYPING_SPEED), 0.0, text.get_total_character_count())
	text.visible_characters = roundi(typing_position)
	pass

func add_text(new_text: String):
	var length_before: int = text.get_total_character_count()
	text.push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
	text.append_text("\n%s" % new_text)
	text.pop_all()
	var length_after: int = text.get_total_character_count()
	text.visible_characters = (length_after - (length_after - length_before))
	typing_position = text.get_visible_characters()
	pass

func add_options(new_options: Dictionary):
	for option_string in new_options:
		options_added += 1
		var option_instance = option.instantiate() as Button
		var rule = new_options.get(option_string, "defaultLeave")
		option_instance.initialize(options_added, option_string)
		option_instance.pressed.connect(_on_option_selected.bind(rule, option_string))
		options_scroll.add_child(option_instance)
	pass

func set_image(path: String):
	var new_image = load("res://Graphics/Dialogue/%s" % path)
	if new_image:
		var texture = ImageTexture.create_from_image(new_image) #IMAGES MUST BE IMPORTED AS 'IMAGE' TYPE!
		image.set_texture(texture)
	pass

func clear_image() -> void:
	set_image("default.png")
	pass

func clear_all():
	clear_text()
	clear_options()
	pass

func clear_text():
	text.clear()
	pass

func clear_options():
	options_added = 0
	for o in options_scroll.get_children():
		options_scroll.call_deferred("remove_child", o)
		o.queue_free()
	pass

func play_sound_effect(path: String):
	get_tree().call_group("audioHandler", "play_once", load("res://Sound/Dialogue/%s" % path), 0.0, "SFX")
	pass

func _on_option_selected(rule: String, _text: String):
	text.push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
	text.push_color(Color.DARK_SLATE_BLUE)
	text.append_text("\n>>> %s" % _text)
	text.pop_all()
	
	var new_query = responseQuery.new()
	new_query.add("concept", "optionSelected")
	new_query.add("option", rule)
	clear_options() #options are always cleared in rules.csv when an option is selected anyway
	get_tree().call_group("dialogueManager", "speak", self, new_query)
	pass
