extends Control

@onready var name_label = $panel/scroll/text_split/name
@onready var description_label = $panel/scroll/text_split/description

const max_hide_time: int = 1000
var hide_time: int = 0:
	set(value):
		hide_time = maxi(0, value)

@export var hide_curve: Curve

func blink(achievement_name: String, achievement_description: String) -> void:
	hide_time = max_hide_time
	name_label.set_text(achievement_name)
	description_label.set_text(achievement_description)
	pass

func _physics_process(delta):
	hide_time -= delta
	set_modulate(Color(1,1,1,hide_curve.sample(remap(hide_time, 0, max_hide_time, 0, 1))))
	pass
