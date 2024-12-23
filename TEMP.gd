@tool
extends Tree

var system = [-1, 0, 0, 0, 1, 1, 0, 0, 2, 2]



func _process(delta):
	clear()
	var root = create_item()
	root.set_text(0, "yo")
	pass
