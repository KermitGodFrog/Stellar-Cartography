extends Node
#can be plotted from anywhere i think... that should be ok!

@onready var radio = $radio

var helpers: Array[radioHelper] = []

var enable_radio: bool = false:
	set(value):
		enable_radio = value
		radio.stream_paused = !value

func _plot_radio(h: radioHelper) -> void:
	var hD = h.duplicate(true)
	hD.time_over_stepped.connect(_on_helper_time_over_stepped.bind(hD))
	helpers.append(hD)
	pass

func _on_helper_time_over_stepped(h: radioHelper) -> void:
	helpers.erase(h)
	pass

func _process(delta: float) -> void:
	if not helpers.size() > 0:
		radio.set_volume_db(linear_to_db(0.0))
	else:
		if enable_radio:
			var total: float = 0.0
			for hA in helpers:
				total += hA.volume_curve.sample(hA.get_time() / hA.get_max_time())
			var avg = total / helpers.size()
			
			for hB in helpers:
				hB.stepTime(delta)
			
			radio.set_volume_db(linear_to_db(avg))
		else:
			radio.set_volume_db(linear_to_db(0.0))
	pass

func _ready() -> void:
	radio.set_volume_db(linear_to_db(0.0))
	pass
