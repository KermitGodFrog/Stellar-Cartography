extends Control

@onready var continue_button = $options_scroll/continue_button
@onready var new_button = $options_scroll/new_button
@onready var create_button = $new_game_popup/new_game/margin/scroll/create_button
@onready var name_edit = $new_game_popup/new_game/margin/scroll/name_edit
@onready var prefix_edit = $new_game_popup/new_game/margin/scroll/prefix_edit
@onready var new_game_popup = $new_game_popup

var SHOW_NEW_GAME_POPUP: bool = false:
	set(value):
		SHOW_NEW_GAME_POPUP = value
		if value == true:
			$new_game_popup.show()
		elif value == false:
			$new_game_popup.hide()

func _ready():
	if ResourceLoader.exists("user://stellar_cartographer_data.res"):
		continue_button.disabled = false
	
	
	
	#var settings_helper = await game_data.loadSettings()
	#if settings_helper != null:
		
		#var relevant_actions = global_data.get_relevant_input_actions() # all starting with SC_
		#for action in relevant_actions:
			#var best_event_if_any
			#var events = InputMap.action_get_events(action)
			#if events: best_event_if_any = events.front()
			#else: best_event_if_any = null
			
			#saving to default events for reset to default option
			#game_data.DEFAULT_RELEVANT_ACTION_EVENTS.append(best_event_if_any)
			
			#if best_event_if_any != null:
				#InputMap.action_erase_events(action)
				#InputMap.action_add_event(action, best_event_if_any)
			
			#THIS IS MEGA BROKE!!!!!! ITS MEANT TO TAKE THE CURRENT ACTION EVENT FROM THE SETTINGS HELPER BUT IT JUST SETS ITSELF TO ITSELF THE FUCKKKKK
	
	
	
	
	pass

func _on_continue_button_pressed():
	global_data.change_scene.emit("res://Scenes/Game/game.tscn", global_data.GAME_INIT_TYPES.CONTINUE)
	pass

func _on_tutorial_button_pressed():
	global_data.change_scene.emit("res://Scenes/Game/game.tscn", global_data.GAME_INIT_TYPES.TUTORIAL)
	pass

func _on_create_button_pressed():
	global_data.change_scene.emit("res://Scenes/Game/game.tscn", global_data.GAME_INIT_TYPES.NEW, {"name": name_edit.text, "prefix": prefix_edit.get_item_text(prefix_edit.selected)})
	pass

func _on_new_button_pressed():
	SHOW_NEW_GAME_POPUP = true
	pass

func _on_return_button_pressed():
	SHOW_NEW_GAME_POPUP = false
	pass
