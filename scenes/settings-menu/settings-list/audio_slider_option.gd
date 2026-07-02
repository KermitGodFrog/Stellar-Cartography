extends "res://scenes/settings-menu/settings-list/option.gd"

@onready var slider = $scroll/slider
@onready var description = $scroll/description
@onready var bus_label = $scroll/bus_label

var linked_bus_idx: int
var last_value: float:
	set(value):
		last_value = value
		emit_signal("changed")

func _ready():
	wID = "AUDIO_SLIDER_LINKED_BUX_IDX_%d" % linked_bus_idx
	slider.connect("value_changed", _on_slider_value_changed)
	super()
	pass

func reset_display() -> void:
	bus_label.set_text(AudioServer.get_bus_name(linked_bus_idx))
	slider.set_value(db_to_linear(AudioServer.get_bus_volume_db(linked_bus_idx)))
	pass

func update_display() -> void:
	description.set_text("%s%s" % [(last_value * 100.0), "%"])
	pass

func _on_slider_value_changed(value: float):
	last_value = value
	update_display()
	pass
