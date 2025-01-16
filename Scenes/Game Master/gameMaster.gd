extends Node

func _ready():
	global_data.change_scene.connect(_change_scene)
	global_data.change_scene.emit("res://Scenes/Main Menu/main_menu.tscn")
	pass

func _change_scene(path_to_scene, with_init_type = null, with_init_data = null):
	for child in get_children():
		call_deferred("remove_child", child)
		#remove_child(child)
		child.queue_free()
	
	var new_scene = load(path_to_scene).instantiate()
	
	if with_init_type != null: new_scene.init_type = with_init_type
	if with_init_data != null: new_scene.init_data = with_init_data
	
	add_child(new_scene)
	pass

func _notification(what): #achievements are on the highest level as they always persist and need to be accessible everywhere, where if it was local to the manager, it would be too difficult to plan i think!
	match what:
		NOTIFICATION_PARENTED:
			game_data.quick_load_achievements()
		NOTIFICATION_WM_CLOSE_REQUEST:
			game_data.quick_save_achievements()
			get_tree().quit()
	pass

func _process(delta): #TEMP
	for i in game_data.ACHIEVEMENTS:
		print(i.unlocked)
