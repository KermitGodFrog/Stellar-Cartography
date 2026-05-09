extends PanelContainer

@onready var current_line_label = $margin/history_scroll/current_line
@onready var player_name_label = $margin/history_scroll/key_info_scroll/player_container/player_name
@onready var player_ship_name_label = $margin/history_scroll/key_info_scroll/player_container/player_ship_name
@onready var total_score_label = $margin/history_scroll/key_info_scroll/data_container/total_score
@onready var systems_traversed_label = $margin/history_scroll/key_info_scroll/data_container/systems_traversed
@onready var stats_menu_init_type_label = $margin/history_scroll/stats_menu_init_type
@onready var total_play_time_label = $margin/history_scroll/key_info_scroll/data_container/total_play_time
@onready var version_label = $margin/version

@onready var v0_8_0_0_conversions: Dictionary = {
	1: player_name_label,
	2: player_ship_name_label,
	3: total_score_label,
	4: systems_traversed_label,
	5: stats_menu_init_type_label,
	6: total_play_time_label
}

func create_from_csv(csv_line: PackedStringArray, _item_count: int) -> void:
	var version: String = csv_line[0]
	for cell_i in csv_line.size():
		if cell_i == 0: continue
		var cell = csv_line[cell_i]
		
		match version:
			"0.8.0.0":
				var _target = v0_8_0_0_conversions.get(cell_i)
				apply_to_target(_target, cell)
	
	current_line_label.set_text("%.f)" % _item_count)
	version_label.set_text(version)
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
			var style_box: StyleBoxFlat = target.get("theme_override_styles/normal")
			style_box = style_box.duplicate()
			
			match _cell:
				"DEATH":
					target.set_text("MISSION\nFAILED")
					style_box.bg_color = Color("7f170e")
				"WIN":
					target.set_text("MISSION\nSUCCESS")
					style_box.bg_color = Color("#3c9371")
				"TUTORIAL":
					target.set_text("TUTORIAL")
					style_box.bg_color = Color("#284b63")
			
			target.set("theme_override_styles/normal", style_box)
		total_play_time_label:
			var time_in_sec: int = roundi(float(_cell))
			var seconds = time_in_sec % 60
			var minutes = (time_in_sec / 60) % 60
			var hours = (time_in_sec / 60) / 60
			var row: String = String()
			if seconds > 0:
				row = "%.fs %s" % [seconds, row]
			if minutes > 0:
				row = "%.fm %s" % [minutes, row]
			if hours > 0:
				row = "%.fh %s" % [hours, row]
			total_play_time_label.set_text("TIME: %s" % row)
		_:
			target.set_text(_cell)
	pass
