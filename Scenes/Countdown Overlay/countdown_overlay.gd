extends Control

@onready var timer = $DEBUG_timer
@onready var time_label = $main_panel/main_scroll/info_scroll/time_label

func _process(delta: float) -> void:
	time_label.set_text("%03d" % roundi(timer.time_left))
