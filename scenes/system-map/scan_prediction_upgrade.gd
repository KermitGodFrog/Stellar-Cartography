extends Node2D #so it has access to the _draw functions!

var _ping_width: int
var _ping_length: int
var _ping_direction: Vector2 = Vector2.ZERO

var _SONAR_POLYGON: PackedVector2Array
var _SONAR_POLYGON_DISPLAY_TIME: float
var _player_position_matrix: Array = [Vector2(0,0), Vector2(0,0)]:
	set(value):
		_player_position_matrix = value
		_on_player_position_matrix_updated()

var draw_scan_arc: bool = false

func _on_upgrade_state_change(upgrade_idx: playerAPI.UPGRADE_ID, state: bool):
	if upgrade_idx == playerAPI.UPGRADE_ID.SCAN_PREDICTION:
		draw_scan_arc = state
	pass

func _physics_process(_delta):
	queue_redraw()
	pass

func _on_sonar_values_changed(ping_width: int, ping_length: int, ping_direction: Vector2):
	_ping_width = ping_width
	_ping_length = ping_length
	_ping_direction = ping_direction
	pass

func _draw():
	if draw_scan_arc and _SONAR_POLYGON and _SONAR_POLYGON_DISPLAY_TIME == 0:
		draw_colored_polygon(_SONAR_POLYGON, Color(Color.NAVY_BLUE, 0.4))
	pass

func _on_player_position_matrix_updated() -> void: #this makes me feel smart and all optimized, but the player position matrix is updated every frame LMAO
	if draw_scan_arc:
		#CLONED FROM system_map.gd
		_ping_length = remap(_ping_width, 5, 90, 300, 100)
		var line = _player_position_matrix[0] + _ping_direction * _ping_length
		
		var a = _player_position_matrix[0]
		var b = line + Vector2(0,_ping_width).rotated(_player_position_matrix[0].angle_to_point(line))
		var c = line + Vector2(0,-_ping_width).rotated(_player_position_matrix[0].angle_to_point(line))
		var points: PackedVector2Array = [a,b,c]
		
		_SONAR_POLYGON = points
	pass
