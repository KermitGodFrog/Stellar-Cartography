extends Control

@onready var achievement_item = preload("res://Scenes/Main Menu/achievement_item.tscn")
@onready var item_locked_stylebox = preload("res://Scenes/Main Menu/item_locked_stylebox.tres")
@onready var item_unlocked_stylebox = preload("res://Scenes/Main Menu/item_unlocked_stylebox.tres")

@onready var spawn_scroll = $panel/margin/scroll/spawn_scroll

func receive_updated_achievements(updated_achievements: Dictionary):
	for n in spawn_scroll.get_children():
		if n.is_in_group("achievement_item"):
			n.queue_free()
	
	for a in updated_achievements:
		var new = achievement_item.instantiate()
		new.initialize(a.name, a.description) # need icon supoort here eventually
		match updated_achievements.get(a):
			true:
				new.add_theme_panel_override(item_unlocked_stylebox)
			false:
				new.add_theme_panel_override(item_locked_stylebox)
		spawn_scroll.add_child(a)
	pass
