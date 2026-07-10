extends "res://scenes/settings-menu/settings-list/option.gd"

@onready var slider = $scroll/slider
@onready var description = $scroll/description
@onready var bus_label = $scroll/bus_label

var linked_bus_idx: int
var last_value: float:
	set(value):
		last_value = value
		emit_signal("changed", get_wID())

func _ready():
	wID = "AUDIO_SLIDER_%s" % AudioServer.get_bus_name(linked_bus_idx).to_snake_case().to_upper()
	super()
	pass

func reset_display_to_applied() -> void: #reset to current applied settings
	bus_label.set_text(AudioServer.get_bus_name(linked_bus_idx))
	slider.set_value(db_to_linear(AudioServer.get_bus_volume_db(linked_bus_idx)))
	pass

func reset_display_to_default() -> void: #reset to default settings
	last_value = db_to_linear(0.0)
	slider.value = last_value # moving the slider manually
	pass

func update_display() -> void:
	description.set_text("%s%s" % [(last_value * 100.0), "%"])
	pass



func _on_slider_value_changed(value: float):
	last_value = value
	update_display()
	pass
