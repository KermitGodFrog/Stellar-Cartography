extends VBoxContainer

@onready var concept_edit = $concept_scroll/concept_edit

@onready var fact_scene: PackedScene = preload("uid://c31jdpsifhyp8")

var active_fact_instances: Array[HBoxContainer] = []
var facts_added: int = 0
var facts_consolidated: Dictionary = {}
var concept_consolidated: String = String()

func reset_all() -> void:
	concept_edit.clear()
	for instance in active_fact_instances:
		instance.queue_free()
	active_fact_instances.clear()
	facts_added = int()
	facts_consolidated = Dictionary()
	concept_consolidated = String()
	pass


func is_facts_valid() -> bool:
	if facts_consolidated.size() == facts_added:
		return true
	return false

func is_concept_valid() -> bool:
	if concept_consolidated.is_empty():
		return false
	return true


func _on_add_fact_button_pressed() -> void:
	var fact_instance = fact_scene.instantiate()
	fact_instance.index = facts_added
	fact_instance.connect("keyValuePairValidUpdate", _on_fact_key_value_pair_valid_update)
	active_fact_instances.append(fact_instance)
	add_child(fact_instance)
	facts_added += 1
	pass



func _on_fact_key_value_pair_valid_update(index: int, key: String, value: String):
	facts_consolidated[index] = [key, value]
	pass

func _on_concept_edit_text_changed(new_text: String) -> void:
	concept_consolidated = new_text
	pass
