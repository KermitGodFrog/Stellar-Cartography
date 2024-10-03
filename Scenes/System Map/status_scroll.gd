extends VBoxContainer
signal removeHullStressForNanites(amount: int, nanites_per_percentage: int)

var last_player_status_matrix: Array = [0,0,0,0]
var player_status_matrix: Array = [0,0,0,0]

@onready var nanites = $nanites_button
@onready var morale = $morale_button
@onready var hull_stress = $hull_stress_button
@onready var hull_deterioration = $hull_deterioration_button
@onready var order = [nanites, hull_stress, hull_deterioration, morale]

func _ready():
	hull_stress.connect("removeHullStressForNanites", _on_remove_hull_stress_for_nanites)
	pass

func _physics_process(_delta):
	for i in player_status_matrix.size():
		if last_player_status_matrix[i] != player_status_matrix[i]:
			order[i].value_change_flash()
	
	nanites.text = "%s" % player_status_matrix[0]
	hull_stress.text = str("%s" % player_status_matrix[1], "%")
	hull_deterioration.text = str("%s" % player_status_matrix[2], "%")
	morale.text = str("%s" % player_status_matrix[3], "%")
	
	last_player_status_matrix = player_status_matrix
	pass

func _on_remove_hull_stress_for_nanites(amount: int, nanites_per_percentage: int) -> void:
	emit_signal("removeHullStressForNanites", amount, nanites_per_percentage)
	pass
