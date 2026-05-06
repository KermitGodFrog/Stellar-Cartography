extends Node

signal tutorialIngressThresholdReached

var _system: starSystemAPI
var _player_position_matrix: Array = [Vector2(0,0), Vector2(0,0)]
var ingress_threshold_prev: bool = false

func _process(_delta: float) -> void:
	if _system != null:
		var ingress = _system.get_first_body_from_display_name("Ingress")
		if ingress != null:
			if _player_position_matrix[0].distance_to(ingress.position) < 20.0:
				if ingress_threshold_prev == false:
					emit_signal("tutorialIngressThresholdReached")
					ingress_threshold_prev = true
	pass
