extends "res://scenes/settings-menu/settings-list/option.gd"

@onready var title = $scroll/title
@onready var dropdown = $scroll/dropdown

func get_current_id() -> int:
	return int()

func reset_display() -> void:
	dropdown.select(get_current_id())
	pass

func _on_dropdown_item_selected(_index: int) -> void:
	emit_signal("changed")
	pass
