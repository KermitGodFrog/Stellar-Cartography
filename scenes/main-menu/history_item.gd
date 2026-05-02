extends PanelContainer

@onready var current_line_label = $history_scroll/current_line
@onready var player_name_label = $history_scroll/key_info_scroll/player_container/player_name
@onready var player_ship_name_label = $history_scroll/key_info_scroll/player_container/player_ship_name
@onready var total_score_label = $history_scroll/key_info_scroll/data_container/total_score
@onready var systems_traversed_label = $history_scroll/key_info_scroll/data_container/systems_traversed
@onready var stats_menu_init_type_label = $history_scroll/stats_menu_init_type
@onready var total_playtime_label = $history_scroll/key_info_scroll/data_container/total_playtime
@onready var version_label = $version

@onready var v0_8_0_0_conversions: Dictionary = {
	1: player_name_label,
	2: player_ship_name_label,
	3: total_score_label,
	4: systems_traversed_label,
	5: stats_menu_init_type_label
}

func create_from_csv(csv_line: PackedStringArray, _item_count: int) -> void:
	var version: String = csv_line[0]
	for cell_i in csv_line.size() - 1:
		if cell_i == 0: continue
		var cell = csv_line[cell_i]
		
		match version:
			"0.8.0.0":
				var _target = v0_8_0_0_conversions.get(cell_i)
				apply_to_target(_target, cell)
	
	current_line_label.set_text("%.f)" % _item_count)
	pass

func apply_to_target(target: Node, _cell: String) -> void:
	match target:
		player_name_label:
			target.set_text("Captain %s" % _cell)
		player_ship_name_label:
			target.set_text("ES %s" % _cell)
		total_score_label:
			target.set_text("SCORE: %s" % _cell)
		systems_traversed_label:
			target.set_text("SYSTEMS: %s" % _cell)
		stats_menu_init_type_label:
			match _cell:
				"DEATH":
					target.set_text("MISSION\nFAILED")
					stats_menu_init_type_label.set("theme_override_styles/normal/bg_color", Color("7f170e"))
					print("death")
				"WIN":
					target.set_text("MISSION\nSUCCESS")
					stats_menu_init_type_label.set("theme_override_styles/normal/bg_color", Color("#3c9371"))
				"TUTORIAL":
					target.set_text("TUTORIAL")
					stats_menu_init_type_label.set("theme_override_styles/normal/bg_color", Color("#284b63"))
		_:
			target.set_text(_cell)
	pass
