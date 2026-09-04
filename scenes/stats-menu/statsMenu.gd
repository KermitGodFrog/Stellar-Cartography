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
	
	if init_type != INIT_TYPES.TUTORIAL:
		var details_helper := game_data.loadUserDetails()
		match init_type:
			INIT_TYPES.DEATH:
				details_helper.lose_condition_runs += 1
				details_helper.total_runs += 1
			INIT_TYPES.WIN:
				details_helper.win_condition_runs += 1
				details_helper.total_runs += 1
		
		try_unlock_mutations_add_items(details_helper)
		
		game_data.saveUserDetails(details_helper)
	else:
		#block out rewards panel w special text
		pass
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

func try_unlock_mutations_add_items(_details_helper: userDetailsHelper) -> void:
	var pending_idx_unlocks: Array[worldAPI.MUTATION_ID] = []
	var appropriate_schedule: Dictionary
	var appropriate_runs_count: int
	var runs_until_next_unlock: int = 0
	
	match init_type:
		INIT_TYPES.DEATH:
			appropriate_schedule.assign(game_data.MUTATION_UNLOCK_LOSE_SCHEDULE)
			appropriate_runs_count = _details_helper.lose_condition_runs
		INIT_TYPES.WIN:
			appropriate_schedule.assign(game_data.MUTATION_UNLOCK_WIN_SCHEDULE)
			appropriate_runs_count = _details_helper.win_condition_runs
	
	for runs in appropriate_schedule:
		if runs <= appropriate_runs_count:
			for idx in appropriate_schedule.get(runs):
				if not is_mutation_unlocked(_details_helper, idx):
					pending_idx_unlocks.append(idx)
		elif runs > appropriate_runs_count:
			runs_until_next_unlock = runs - appropriate_runs_count
		
	#^^^ if unlocks were missed due to an update, then the next run will result in ALL of the missed mutations being unlocked! quite immaculate if i do say so myself!  
	
	_details_helper.unlocked_mutations.append_array(pending_idx_unlocks)
	
	print_debug("DETAILS HELPER UNLOCKED MUTATIONS: ", _details_helper.unlocked_mutations)
	print_debug("RUNS UNTIL NEXT UNLOCK: ", runs_until_next_unlock)
	#now add items, including an item at the bottom showing the runs until next unlock \/
	
	for idx in pending_idx_unlocks:
		
		
		
		
		
		
		
		
		
		
		
		
		pass
	
	
	pass















#misc

func is_mutation_unlocked(_details_helper: userDetailsHelper, mutation_idx: worldAPI.MUTATION_ID) -> bool:
	if _details_helper.unlocked_mutations.has(mutation_idx):
		return true
	return false
