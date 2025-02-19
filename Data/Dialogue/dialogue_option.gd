extends Button

@onready var option_text = $option_margin/option_text

var _text: String 
var iteration: int


func initialize(_iteration: int, __text: String) -> void:
	_text = __text
	iteration = _iteration
	pass

func _ready() -> void:
	option_text.append_text("%d) %s" % [iteration, _text])
	pass
