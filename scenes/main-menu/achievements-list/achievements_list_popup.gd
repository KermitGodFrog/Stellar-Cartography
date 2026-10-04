extends Control

signal returnButtonPressed

@onready var achievement_item = preload("uid://b34lxvbuquaso")
@onready var item_locked_stylebox = preload("uid://cnaci0fj8gv3d")
@onready var item_unlocked_stylebox = preload("uid://hami5xfvw4k0")
@onready var exploration_trophy = preload("uid://id0eoqh6iql4")

@onready var spawn_scroll = $panel/margin/actions_items_split/scroll/spawn_scroll
@onready var total_progress = $panel/margin/actions_items_split/total_progress

func receive_updated_achievements(updated_achievements: Dictionary):
	for i in spawn_scroll.get_children():
		if i.is_in_group("achievement_item"):
			i.queue_free()
	
	for a in updated_achievements:
		var new = achievement_item.instantiate()
		new.connect("ready", _on_achievement_item_ready.bind(new, updated_achievements, a))
		spawn_scroll.add_child(new)
	
	var achievements_count = updated_achievements.values().size()
	var u_achievements_count = updated_achievements.values().reduce(iterate_if_unlocked, 0)
	total_progress.set_max(achievements_count)
	
	await visibility_changed
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(total_progress, "value", u_achievements_count, 2)
	pass
func iterate_if_unlocked(accum: int, unlocked: bool) -> int:
	if unlocked:
		return accum + 1
	else:
		return accum

func _on_achievement_item_ready(new, updated_achievements, a: responseAchievement) -> void:
	var display_hidden: bool = false
	var trophy = null
	match updated_achievements.get(a):
		true:
			new["theme_override_styles/panel"] = item_unlocked_stylebox
		false:
			new["theme_override_styles/panel"] = item_locked_stylebox
			if a.hidden_until_unlocked:
				display_hidden = true
	match a.trophy_type:
		responseAchievement.TROPHY_TYPES.EXPLORATION:
			trophy = exploration_trophy
	new.initialize(a.name, a.description, display_hidden, trophy) # need icon supoort here eventually
	pass

func _on_achievements_return_button_pressed():
	emit_signal("returnButtonPressed")
	pass
