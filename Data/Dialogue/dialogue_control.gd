extends Control

@onready var image = $margin/panel/main_scroll/content/content_scroll/image
@onready var text = $margin/panel/main_scroll/interaction/interaction_scroll/text
@onready var options_scroll = $margin/panel/main_scroll/interaction/interaction_scroll/scroll/options_scroll
@onready var music = $music
@onready var option = preload("res://Data/Dialogue/dialogue_option.tscn")

@onready var dialogue_click_light = preload("res://Sound/SFX/dialogue_click_light.tres")
@onready var dialogue_click_heavy = preload("res://Sound/SFX/dialogue_click_heavy.tres")
@onready var dialogue_click_cancel = preload("res://Sound/SFX/dialogue_click_cancel.tres")

const TYPING_SPEED: int = 500 #could have this in settings! good test for a slider option!
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
	for option_text in new_options:
		options_added += 1
		var option_instance = option.instantiate() as Button
		var rule = new_options.get(option_text, "defaultLeave")
		option_instance.initialize(rule, option_text, options_added)
		option_instance.pressed.connect(_on_option_selected.bind(rule, option_text))
		option_instance.mouse_entered.connect(_on_option_mouse_entered)
		options_scroll.add_child(option_instance)
	pass

func set_image(path: String):
	var new_image = load("res://Graphics/Dialogue/%s" % path)
	if new_image:
		var texture = ImageTexture.create_from_image(new_image) #IMAGES MUST BE IMPORTED AS 'IMAGE' TYPE!
		texture.set_size_override(Vector2i(450, 250))
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

func play_sound_effect(path: String) -> void:
	var global_path = "res://Sound/dialogue/sfx/%s" % path
	get_tree().call_group("audioHandler", "play_once", load(global_path), 0.0, "SFX")
	pass

func play_music(path: String) -> void:
	var global_path = "res://Sound/dialogue/music/%s" % path
	var instance = load(global_path)
	if music.get_stream() != null:
		if music.stream.get_path() == global_path:
			music.stream_paused = false
			return
	music.set_stream(instance)
	music.play()
	pass

func stop_music() -> void:
	music.stream_paused = true
	pass

func clear_music() -> void:
	music.set_stream(null)
	pass

func _on_option_selected(option_rule: String, option_text: String):
	text.push_paragraph(HORIZONTAL_ALIGNMENT_LEFT)
	text.push_color(Color.DARK_SLATE_BLUE)
	text.append_text("\n>>> %s" % option_text)
	text.pop_all()
	
	var new_query = responseQuery.new()
	new_query.add("concept", "optionSelected")
	new_query.add("option", option_rule)
	clear_options() #options are always cleared in rules.csv when an option is selected anyway
	stop_music() #music is USUALLY stopped after selecting an option anyway! :)
	get_tree().call_group("dialogueManager", "speak", self, new_query)
	
	get_tree().call_group("audioHandler", "play_once", dialogue_click_heavy, 0.0, "SFX")
	pass

func _on_option_mouse_entered() -> void:
	get_tree().call_group("audioHandler", "play_once", dialogue_click_light, 0.0, "SFX")
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed():
			if event.keycode >= 49 and event.keycode <= 57:
				var selecting = int(OS.get_keycode_string(event.keycode))
				
				for option_instance in options_scroll.get_children():
					if selecting == option_instance.iteration:
						_on_option_selected(option_instance.rule, option_instance._text)
						return
				
				get_tree().call_group("audioHandler", "play_once", dialogue_click_cancel, 0.0, "SFX")
	pass
