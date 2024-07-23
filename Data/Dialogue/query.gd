extends Resource
class_name responseQuery

var facts: Dictionary #aka context

func add(key, value):
	facts[key] = value
	pass
