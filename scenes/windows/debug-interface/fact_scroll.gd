extends HBoxContainer

signal keyValuePairValidUpdate(_index: int, _key: String, _value: String)

@onready var key = $key_edit
@onready var value = $value_edit

var index: int = 0

func is_valid() -> bool:
	if key.text.is_empty() and value.text.is_empty():
		return false
	return true

func _on_key_edit_text_changed(new_text: String) -> void:
	if is_valid(): emit_signal("keyValuePairValidUpdate", index, new_text, value.text)
	pass 

func _on_value_edit_text_changed(new_text: String) -> void:
	if is_valid(): emit_signal("keyValuePairValidUpdate", index, key.text, new_text)
	pass
