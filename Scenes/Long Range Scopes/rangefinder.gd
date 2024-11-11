extends ColorRect

const font = preload("res://Graphics/Fonts/RobotoMono Medium.ttf")
var DRAW_MATRICIES: Array[Array] = [[]]

func draw_rangefinder(_DRAW_MATRICIES: Array[Array]):
	DRAW_MATRICIES = _DRAW_MATRICIES
	queue_redraw()
	pass

func _draw():
	for MATRIX in DRAW_MATRICIES:
		if not MATRIX.is_empty():
			draw_circle(MATRIX.front(), 10, Color.RED)
			draw_string(font, MATRIX.front() + Vector2(20,0), str(roundi(MATRIX.back())), HORIZONTAL_ALIGNMENT_FILL, -1, 32, Color.RED)
	pass
