extends Control
@onready var debug_texture = load("res://Graphics/Misc/denied.png")
@onready var tree = $tree_test

var system: starSystemAPI = null:
	set(value):
		system = value
		generate()

var collapsed_cache: Dictionary = {}

func _process(delta):
	pass




func generate() -> void:
	tree.clear()
	recursive_add(system.get_first_star(), null) #RECUSION IS SO COOL
	pass

func recursive_add(body: bodyAPI, parent: TreeItem) -> void:
	var new = create_item_for_body(body, parent)
	for b in system.get_bodies_with_hook_identifier(body.get_identifier()):
		recursive_add(b, new)
	pass

func create_item_for_body(body: bodyAPI, parent: TreeItem) -> TreeItem:
	var item: TreeItem = tree.create_item(parent)
	item.set_text(0, body.get_display_name())
	item.set_metadata(0, body.get_identifier())
	var c = collapsed_cache.get(body.get_identifier())
	if c != null:
		item.set_collapsed(c)
	return item

func _on_tree_test_item_collapsed(item):
	collapsed_cache[item.get_metadata(0)] = item.is_collapsed()
	pass

func _on_tree_test_item_selected():
	print("ITEM SELECTED!")
	pass
