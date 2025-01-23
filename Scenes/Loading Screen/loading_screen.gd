extends Control

@onready var progress_fill = $progress_fill

func update_progress(new_progress: float):
	progress_fill.set_value(new_progress)
	pass
