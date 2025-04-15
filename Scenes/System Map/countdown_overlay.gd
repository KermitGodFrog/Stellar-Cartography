extends Control
#DISPLAYS a countdown when needed. DOES NOT do any internal time-base calculations. Has juristicion over time visual effects (e.g, flashing text when low) BUT NOT time auditority effects which are juristiction of GAME.

@onready var time_label = $main_panel/main_margin/main_scroll/info_scroll/time_label
@onready var hull_stress_label = $main_panel/main_margin/main_scroll/info_scroll/hull_stress_increase_label
@onready var title_label = $main_panel/main_margin/main_scroll/title_label
@onready var description_label = $main_panel/main_margin/main_scroll/description_label

func update_info(_title: String, _description: String, _hull_stress: int):
	title_label.set_text(_title)
	description_label.set_text(_description)
	hull_stress_label.set_text("+%d%%" % _hull_stress)
	pass

func update_time(_time: float):
	time_label.set_text("%03d" % roundi(_time))
	#special effects and shit if the time is LOW (VISUAL ONLY)
	pass
