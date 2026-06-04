extends Control
signal removeHullStressForNanites(amount: int, nanites_per_percentage: int)
signal updateScannerDisplayTimes(_new_profile_time: float, _new_power_time: float)

var last_player_status_matrix: Array = [0,0,0,0]
var player_status_matrix: Array = [0,0,0,0]
var player_adj_scanner_matrix: Array = [0,0]
var player_adj_speed: int = 0

@onready var nanites = $status_scroll/primary_panel/primary_margin/unadjusted_values/value_nanites_scroll/nanites_button
@onready var morale = $status_scroll/primary_panel/primary_margin/unadjusted_values/value_nanites_scroll/morale_button
@onready var hull_stress = $status_scroll/primary_panel/primary_margin/unadjusted_values/stress_deterioration_scroll/hull_stress_button
@onready var hull_deterioration = $status_scroll/primary_panel/primary_margin/unadjusted_values/stress_deterioration_scroll/hull_deterioration_button
@onready var scanner_power = $status_scroll/secondary_scroll/secondary_panel2/secondary_margin/bisect/adjusted_values/scanner_power_button
@onready var scanner_profile = $status_scroll/secondary_scroll/secondary_panel2/secondary_margin/bisect/adjusted_values/scanner_profile_button
@onready var speed = $status_scroll/secondary_scroll/secondary_panel2/secondary_margin/bisect/adjusted_values/speed_button
@onready var prox_blinker_container = $status_scroll/secondary_scroll/secondary_panel2/secondary_margin/bisect/proximity_blinker/texture_container
@onready var order = [nanites, hull_stress, hull_deterioration, morale]

func _ready():
	hull_stress.connect("removeHullStressForNanites", _on_remove_hull_stress_for_nanites)
	pass

func _physics_process(_delta):
	for i in player_status_matrix.size():
		if last_player_status_matrix[i] != player_status_matrix[i]:
			order[i].value_change_flash()
			order[i].update_danger(player_status_matrix[i])
	
	#primary
	nanites.text = "%.fK" % (player_status_matrix[0] / 1000)
	nanites.tooltip_title = "Nanites (%d)" % player_status_matrix[0]
	hull_stress.text = "%.f%%" % player_status_matrix[1]
	hull_deterioration.text = "%.f%%" % player_status_matrix[2]
	morale.text = "%.f%%" % player_status_matrix[3]
	last_player_status_matrix = player_status_matrix
	#secondary
	scanner_profile.text = "%.f" % player_adj_scanner_matrix[0]
	scanner_profile.tooltip_title = "Scanner Profile (%dR%c)" % [player_adj_scanner_matrix[0], "☉"]
	scanner_power.text = "%.f" % player_adj_scanner_matrix[1]
	scanner_power.tooltip_title = "Scanner Power (%dR%c)" % [player_adj_scanner_matrix[1], "☉"]
	speed.text = "%.f" % player_adj_speed
	speed.tooltip_title = "Speed (%dR%c/s)" % [player_adj_speed, "☉"]
	prox_blinker_container.tooltip_title = "Proximity Blinker (%dR%c)" % [int(player_adj_scanner_matrix[1] * 4.0), "☉"]
	pass

func _on_remove_hull_stress_for_nanites(amount: int, nanites_per_percentage: int) -> void:
	emit_signal("removeHullStressForNanites", amount, nanites_per_percentage)
	pass

func _on_scanner_profile_button_mouse_entered() -> void:
	emit_signal("updateScannerDisplayTimes", 5.0, 0.0)
	pass

func _on_scanner_power_button_mouse_entered() -> void:
	emit_signal("updateScannerDisplayTimes", 0.0, 5.0)
	pass
