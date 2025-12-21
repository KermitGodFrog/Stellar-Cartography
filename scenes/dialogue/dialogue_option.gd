extends Button

@onready var option_text = $option_margin/option_text

var rule: String #has to be here because of the whole press-number-key-to-select thing
var _text: String 
var iteration: int

func initialize(_rule: String, __text: String, _iteration: int) -> void:
	rule = _rule
	_text = __text #IT IS _text AND NOT text BECAUSE IF IT WAS text IT WOULD REDEFINE THE CLASS VARIABLE text
	iteration = _iteration
	pass

func _ready() -> void:
	option_text.append_text("%d) %s" % [iteration, _text])
	pass
