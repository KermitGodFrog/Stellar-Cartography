extends Node3D

func _ready():
	create_and_connect_timer()
	print_debug("SPACE WHALE READY!")
	pass

func _on_timer_timeout():
	create_and_connect_timer()
	var animation = ["tail_wag", "tail_wag2"].pick_random()
	var animation_player: AnimationPlayer = get_node("AnimationPlayer")
	animation_player.play(animation)
	print_debug("SPACE WHALE ANIMATION PLAYING")
	pass


func create_and_connect_timer():
	var timer = get_tree().create_timer(global_data.get_randi(5, 30), false, true, false)
	timer.connect("timeout", _on_timer_timeout)
	pass
