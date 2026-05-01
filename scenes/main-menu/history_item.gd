extends PanelContainer

@onready var current_line_label = $history_scroll/current_line
@onready var player_name_label = $history_scroll/player_name
@onready var player_ship_name_label = $history_scroll/player_ship_name
@onready var total_score_label = $history_scroll/total_score
@onready var systems_traversed_label = $history_scroll/systems_traversed
@onready var stats_menu_init_type_label = $history_scroll/stats_menu_init_type

@onready var v0_8_0_0_conversions: Dictionary = {
	1: player_name_label,
	2: player_ship_name_label,
	3: total_score_label,
	4: systems_traversed_label,
	5: stats_menu_init_type_label
}

func create_from_csv(csv_line: PackedStringArray, _current_line: int) -> void:
	print("CREATING FROM CSV")
	var version: String = csv_line[0]
	for cell_i in csv_line.size() - 1:
		if cell_i == 0: continue
		var cell = csv_line[cell_i]
		
		print(cell)
		
		match version:
			"0.8.0.0":
				var _target = v0_8_0_0_conversions.get(cell_i)
				apply_to_target(_target, cell)
	
	current_line_label.set_text("%.f)" % _current_line)
	pass

func apply_to_target(target: Node, _cell: String) -> void:
	match target:
		stats_menu_init_type_label:
			match _cell:
				"DEATH":
					target.set_text("MISSION FAILED")
				"WIN":
					target.set_text("MISSION ACCOMPLISHED")
				"TUTORIAL":
					target.set_text("TUTORIAL")
		_:
			target.set_text(_cell)
	pass
