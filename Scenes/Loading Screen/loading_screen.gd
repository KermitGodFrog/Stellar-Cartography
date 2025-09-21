extends Control

signal load_confirmation

@onready var progress_fill = $progress_fill
@onready var tip_control = $tip_control
@onready var continue_label = $continue_label

var ghost_progress: float = 0.0
var estimated_progress: float = 0.0

func update_progress(new_progress: float):
	ghost_progress = new_progress
	pass

func _process(delta):
	estimated_progress = lerpf(estimated_progress, ghost_progress, delta)
	progress_fill.set_value(estimated_progress)
	pass

func disable_tips() -> void:
	tip_control.hide()
	pass

func show_continue_popup() -> void:
	continue_label.show()
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("SC_LOAD_CONFIRMATION"):
		emit_signal("load_confirmation")
	pass
