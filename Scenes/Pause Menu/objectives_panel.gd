extends PanelContainer

@onready var tree = $objectives_tree

var parsed_objectives: Dictionary = {}

func update(_parsed_objectives: Dictionary) -> void: #{file name: objectiveAPI}
	parsed_objectives = _parsed_objectives
	generate()
	pass

func generate():
	tree.clear()
	var root = tree.create_item()
	for wid in parsed_objectives:
		var o = parsed_objectives.get(wid)
		if o.parent.is_empty():
			recursive_add(o, root)
	pass

func recursive_add(objective: objectiveAPI, parent: TreeItem):
	var new = create_item_for_objective(objective, parent)
	for s in objective.sub_objectives:
		var wid = parsed_objectives.find_key(s)
		if wid != null:
			var sub = parsed_objectives.get(wid)
			create_item_for_objective(sub, new)
	pass

func create_item_for_objective(objective: objectiveAPI, parent: TreeItem):
	var item = tree.create_item(parent)
	item.set_text(0, objective.title)
	return item
