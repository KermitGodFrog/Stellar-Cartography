extends ColorRect

var TEMP_DRAW_POSITIONS: Array = [] #TEMP !!!!!!!!



func _draw():
	for i in TEMP_DRAW_POSITIONS:
		draw_circle(i, 3, Color.RED)
	pass
