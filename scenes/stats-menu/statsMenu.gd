extends Node

var _pause_mode: game_data.PAUSE_MODES = game_data.PAUSE_MODES.NONE:
	set(value):
		_pause_mode = value
		_on_pause_mode_changed(value)
signal queuePauseMode(new_mode: game_data.PAUSE_MODES)
signal setPauseMode(new_mode: game_data.PAUSE_MODES)
func _on_pause_mode_changed(value):
	match value:
		game_data.PAUSE_MODES.NONE:
			stats_control.hide()
		game_data.PAUSE_MODES.STATS_MENU:
			stats_control.show()
			_on_open()
	pass

signal statsMenuQuit(_init_type: INIT_TYPES)

@onready var stats_control = $stats_canvas/stats_control
@onready var init_type_label = $stats_canvas/stats_control/main_scroll/init_type_label
@onready var stats_body_scroll = $stats_canvas/stats_control/main_scroll/stats_rewards_scroll/stats_panel/stats_scroll/body_margin/body_scroll
enum INIT_TYPES {DEATH, WIN, TUTORIAL}
var init_type: INIT_TYPES = INIT_TYPES.DEATH
var player_stats: Dictionary = {}

@onready var statistic_scene = preload("uid://brnijoy5m2487")

func _on_exit_to_main_menu_button_pressed():
	emit_signal("statsMenuQuit", init_type)
	emit_signal("setPauseMode", game_data.PAUSE_MODES.NONE)
	pass 

func _on_open() -> void:
	match init_type:
		INIT_TYPES.DEATH:
			init_type_label.set_text("YOU ARE DEAD")
			init_type_label.set("theme_override_colors/font_shadow_color", Color.WEB_MAROON)
			init_type_label.set("theme_override_colors/font_outline_color", Color.BLACK)
		INIT_TYPES.WIN:
			init_type_label.set_text("YOU HAVE REACHED NEW EDEN")
			init_type_label.set("theme_override_colors/font_shadow_color", Color.WEB_GREEN)
			init_type_label.set("theme_override_colors/font_outline_color", Color.BLACK)
		INIT_TYPES.TUTORIAL:
			init_type_label.set_text("YOU HAVE COMPLETED THE TUTORIAL")
	for title in player_stats:
		var new = statistic_scene.instantiate()
		new.connect("ready", _on_statistic_instance_ready.bind(new, title))
		stats_body_scroll.add_child(new)
	pass

func _on_statistic_instance_ready(instance: Node, title: String) -> void:
	instance.title_label.set_text(title)
	var value_text: String = String()
	var value: Variant = player_stats.get(title)
	match title:
		"Net Worth": value_text = "%.fn" % player_stats.get(title)
		_: value_text = str(value)
	instance.value_label.set_text(value_text)
	pass
