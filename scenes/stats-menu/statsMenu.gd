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
@onready var rewards_body_scroll = $stats_canvas/stats_control/main_scroll/stats_rewards_scroll/rewards_panel/rewards_scroll/body_margin/body_scroll
enum INIT_TYPES {DEATH, WIN, TUTORIAL}
var init_type: INIT_TYPES = INIT_TYPES.DEATH
var player_stats: Dictionary = {}

@onready var statistic_scene = preload("uid://brnijoy5m2487")
@onready var mutation_item_scene = preload("uid://dte1ssronei0")
@onready var rnu_item_scene = preload("uid://b568o8s45lksu")
@onready var station_upgrade = preload("uid://crt73kp6x2bbe")

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
	
	#print_debug("DETAILS HELPER UNLOCKED MUTATIONS: ", _details_helper.unlocked_mutations)
	print_debug("RUNS UNTIL NEXT UNLOCK: ", runs_until_next_unlock)
	#now add items, including an item at the bottom showing the runs until next unlock \/
	
	var current_time: float = 0.0
	for idx in pending_idx_unlocks:
		var item := global_data.get_mutation_item(idx, _on_mutation_item_ready)
		rewards_body_scroll.add_child(item)
		var added_time: float = 0.15
		if pending_idx_unlocks.front() != idx:
			added_time = global_data.get_randf(0.5, 1.75)
		get_tree().create_timer(current_time + added_time).timeout.connect(_on_mutation_item_popup.bind(item))
		current_time += added_time
	if runs_until_next_unlock > 0:
		var rnu_item = rnu_item_scene.instantiate()
		rnu_item.connect("ready", _on_rnu_item_ready.bind(rnu_item, runs_until_next_unlock))
		rewards_body_scroll.add_child(rnu_item)
		var added_time: float = 0.15
		if pending_idx_unlocks.size() > 0:
			added_time = 2.0
		get_tree().create_timer(current_time + added_time).timeout.connect(_on_rnu_item_popup.bind(rnu_item))
	pass

func _on_mutation_item_ready(item: Node, idx: worldAPI.MUTATION_ID) -> void:
	item.init_type = item.INIT_TYPES.DISPLAY
	item.initialize(idx)
	pass
func _on_mutation_item_popup(item: Node) -> void:
	item.popup()
	get_tree().call_group("audioHandler", "play_once", station_upgrade, 0.0, "SFX")
	pass
func _on_rnu_item_ready(item: Node, _runs_until_next_unlock: int) -> void:
	item.hide()
	item.rnu_label.set_text("%d more %s run(s) until next unlock!" % [_runs_until_next_unlock, INIT_TYPES.find_key(init_type)])
	pass
func _on_rnu_item_popup(item: Node) -> void:
	item.show()
	get_tree().call_group("audioHandler", "play_once", load("uid://dt1d2ijrj4emm"), -12, "SFX")
	pass



#misc

func is_mutation_unlocked(_details_helper: userDetailsHelper, mutation_idx: worldAPI.MUTATION_ID) -> bool:
	if _details_helper.unlocked_mutations.has(mutation_idx):
		return true
	return false
