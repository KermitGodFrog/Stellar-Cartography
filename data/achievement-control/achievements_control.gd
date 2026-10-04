extends Control
#MIGHT BE SOON CHILD OF GAME.GD

@onready var name_label = $panel/scroll/text_split/name
@onready var description_label = $panel/scroll/text_split/description
@onready var trophy_texture = $panel/scroll/trophy_center/trophy

@onready var normal_trophy = preload("uid://bkagb0wi4hewb")
@onready var exploration_trophy = preload("uid://id0eoqh6iql4")

const max_hide_time: int = 500
var hide_time: int = 0:
	set(value):
		hide_time = maxi(0, value)
		if hide_time == 0:
			try_display_next_achievement()
var queue: Array[responseAchievement] = []

@export var hide_curve: Curve

func queue_achievement(new_achievement: responseAchievement) -> void:
	queue.append(new_achievement)
	pass

func try_display_next_achievement() -> void:
	if queue.size() > 0:
		var a = queue.pop_front()
		if a != null:
			#print_debug("ACHIEVEMENTS CONTROL: SHOWING NEXT ACHIEVEMENT ", a.name)
			blink(a.name, a.description, a.trophy_type)
	pass

func blink(achievement_name: String, achievement_description: String, achievement_trophy_type: responseAchievement.TROPHY_TYPES) -> void:
	get_tree().call_group("audioHandler", "play_once", load("uid://h5od0egtjhfq"), 0.0, "SFX")
	hide_time = max_hide_time
	name_label.set_text(achievement_name)
	description_label.set_text(achievement_description)
	match achievement_trophy_type:
		responseAchievement.TROPHY_TYPES.NORMAL:
			trophy_texture.set_texture(normal_trophy)
		responseAchievement.TROPHY_TYPES.EXPLORATION:
			trophy_texture.set_texture(exploration_trophy)
	pass

func _physics_process(delta):
	hide_time -= delta
	set_modulate(Color(1,1,1,hide_curve.sample(remap(hide_time, 0, max_hide_time, 0, 1))))
	pass
