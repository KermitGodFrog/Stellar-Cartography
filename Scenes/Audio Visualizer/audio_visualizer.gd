extends Control

@onready var clicks
@onready var rads
@onready var chimes
@onready var pings
@onready var gurgles

func initialize(clicks_curve: Curve, rads_curve: Curve, chimes_curve: Curve, pings_curve: Curve, gurgles_curve: Curve):
	pass

func _physics_process(delta):
	var master_bus_volume = (AudioServer.get_bus_peak_volume_left_db(0,0) + AudioServer.get_bus_peak_volume_right_db(0,0)) / 2
	pass
