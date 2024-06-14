extends Control

signal sonarPing(dir: Vector2, length: int)

var ping_direction: Vector2 = Vector2.ZERO
var ping_length: int

var mouse_over_ui: bool = false

@onready var ping_length_slider = $flow_container/ping_length_slider

func _physics_process(delta):
	ping_length = ping_length_slider.value
	
	
	
	if Input.is_action_pressed("left_mouse") and not mouse_over_ui:
		ping_direction = get_screen_centre().direction_to(get_global_mouse_position())
	queue_redraw()
	pass

func _draw():
	var line = get_screen_centre() + ping_direction * 150.0
	draw_arc(get_screen_centre(), 100, get_screen_centre().angle_to_point(line) + deg_to_rad(ping_length), get_screen_centre().angle_to_point(line) - deg_to_rad(ping_length), 100, Color.RED, 10)
	pass

func get_screen_centre():
	return (get_viewport_rect().size / 2)

func _on_sonar_window_close_requested():
	owner.hide()
	pass

func _on_ping_button_pressed():
	emit_signal("sonarPing", ping_direction, ping_length)
	pass


























func _on_flow_container_mouse_entered():
	mouse_over_ui = true
	pass 


func _on_flow_container_mouse_exited():
	mouse_over_ui = false
	pass
