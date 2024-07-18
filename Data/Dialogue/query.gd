extends Resource
class_name responseQuery

var facts: Dictionary #aka context

func add(key: String, value: String):
	facts[key] = value
	pass
