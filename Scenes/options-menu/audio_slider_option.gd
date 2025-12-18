extends HBoxContainer

@onready var slider = $slider
@onready var description = $description
@onready var bus_label = $bus_label

var linked_bus_idx: int
var last_value: float

func reset_display() -> void:
	bus_label.set_text(AudioServer.get_bus_name(linked_bus_idx))
	slider.set_value(db_to_linear(AudioServer.get_bus_volume_db(linked_bus_idx)))
	pass

func update_display() -> void:
	description.set_text("%s%s" % [(last_value * 100.0), "%"])
	pass

func _ready():
	slider.connect("value_changed", _on_slider_value_changed)
	pass

func _on_slider_value_changed(value: float):
	last_value = value
	update_display()
	pass
