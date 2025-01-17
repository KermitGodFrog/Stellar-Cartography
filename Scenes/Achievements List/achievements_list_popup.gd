extends Control

signal returnButtonPressed

@onready var achievement_item = preload("res://Scenes/Achievements List/achievement_item.tscn")
@onready var item_locked_stylebox = preload("res://Scenes/Achievements List/item_locked_stylebox.tres")
@onready var item_unlocked_stylebox = preload("res://Scenes/Achievements List/item_unlocked_stylebox.tres")

@onready var spawn_scroll = $panel/margin/actions_items_split/scroll/spawn_scroll

func receive_updated_achievements(updated_achievements: Dictionary):
	for i in spawn_scroll.get_children():
		if i.is_in_group("achievement_item"):
			i.queue_free()
	
	for a in updated_achievements:
		var new = achievement_item.instantiate()
		new.connect("ready", _on_achievement_item_ready.bind(new, updated_achievements, a))
		spawn_scroll.add_child(new)
	pass

func _on_achievement_item_ready(new, updated_achievements, a) -> void:
	new.initialize(a.name, a.description) # need icon supoort here eventually
	match updated_achievements.get(a):
		true:
			new["theme_override_styles/panel"] = item_unlocked_stylebox
		false:
			new["theme_override_styles/panel"] = item_locked_stylebox
	pass

func _on_achievements_return_button_pressed():
	emit_signal("returnButtonPressed")
	pass
