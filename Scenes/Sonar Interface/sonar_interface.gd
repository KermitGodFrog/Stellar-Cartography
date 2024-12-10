extends Control

signal sonarPing(ping_width: int, ping_length: int)

var ping_width: int
var ping_length: int
var ping_direction: Vector2 = Vector2.ZERO

@onready var ping_width_slider = $flow_container/ping_width_slider
@onready var ping_cooldown_timer = $ping_cooldown_timer
@onready var cooldown_label = $cooldown_label

func _physics_process(_delta):
	ping_width = ping_width_slider.value
	
	if not ping_cooldown_timer.is_stopped():
		cooldown_label.set_text(str(round(ping_cooldown_timer.time_left)))
	else:
		cooldown_label.set_text("")
	
	queue_redraw()
	pass

func _gui_input(event):
	if event.is_action_pressed("INTERACT1_LEFT_MOUSE"):
		ping_direction = get_screen_centre().direction_to(get_global_mouse_position())
	pass

func _draw():
	ping_length = remap(ping_width, 5, 90, 300, 100)
	var line = get_screen_centre() + ping_direction * ping_length
	
	#draw_arc(get_screen_centre(), radii, get_screen_centre().angle_to_point(line) + deg_to_rad(ping_length), get_screen_centre().angle_to_point(line) - deg_to_rad(ping_length), 100, Color.WHITE, 2)
	#draw_arc(get_screen_centre(), radii + 10, get_screen_centre().angle_to_point(line) + deg_to_rad(ping_length), get_screen_centre().angle_to_point(line) - deg_to_rad(ping_length), 100, Color.WHITE, 4)
	#draw_arc(get_screen_centre(), radii + 20, get_screen_centre().angle_to_point(line) + deg_to_rad(ping_length), get_screen_centre().angle_to_point(line) - deg_to_rad(ping_length), 100, Color.WHITE, 8)
	
	var a = get_screen_centre()
	var b = line + Vector2(0,ping_width).rotated(get_screen_centre().angle_to_point(line))
	var c = line + Vector2(0,-ping_width).rotated(get_screen_centre().angle_to_point(line))
	var points: PackedVector2Array = [a,b,c]
	draw_colored_polygon(points, Color.RED)
	pass

func get_screen_centre():
	return (get_viewport_rect().size / 2)

func _on_ping_button_pressed():
	if ping_cooldown_timer.is_stopped():
		emit_signal("sonarPing", ping_width, ping_length, ping_direction)
		ping_cooldown_timer.start()
	pass

