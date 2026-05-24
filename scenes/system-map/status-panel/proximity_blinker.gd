extends Control

signal condition_changed(_active: bool)

@onready var blinker = $scroll/texture_container/blinker
@onready var light = $scroll/texture_container/light

@onready var blinker_standby_tex = preload("uid://bdjtfvb35byds")
@onready var blinker_warn_tex = preload("uid://3afy6kavs1kh")

var time: float = 0.0

var active: bool = false:
	set(value):
		if value != active:
			emit_signal("condition_changed", value)
		active = value

func _ready() -> void:
	connect("condition_changed", _on_condition_changed)
	pass

func _on_condition_changed(_active: bool) -> void:
	match _active:
		true:
			blinker.set_texture(blinker_warn_tex)
			light.show()
		false:
			blinker.set_texture(blinker_standby_tex)
			light.hide()
	pass

func _process(delta: float) -> void:
	time += delta
	var update_color = Color.DARK_RED
	update_color.a = clampf(sin(time), 0.0, 0.3)
	light.set_modulate(update_color)
	pass
