extends Control
#MIGHT BE SOON CHILD OF GAME.GD

@onready var name_label = $panel/scroll/text_split/name
@onready var description_label = $panel/scroll/text_split/description

const max_hide_time: int = 350
var hide_time: int = 0:
	set(value):
		hide_time = maxi(0, value)
		if hide_time == 0:
			try_display_next_achievement()
var queue: Array[achievement] = []

@export var hide_curve: Curve

func queue_achievement(new_achievement: achievement) -> void:
	queue.append(new_achievement)
	pass

func try_display_next_achievement() -> void:
	if queue.size() > 0:
		var a = queue.pop_front()
		if a != null:
			#print_debug("ACHIEVEMENTS CONTROL: SHOWING NEXT ACHIEVEMENT ", a.name)
			blink(a.name, a.description)
	pass

func blink(achievement_name: String, achievement_description: String) -> void:
	hide_time = max_hide_time
	name_label.set_text(achievement_name)
	description_label.set_text(achievement_description)
	pass

func _physics_process(delta):
	hide_time -= delta
	set_modulate(Color(1,1,1,hide_curve.sample(remap(hide_time, 0, max_hide_time, 0, 1))))
	pass
