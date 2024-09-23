extends Node3D

var initial_basis: Basis
var target_basis: Basis


func _ready():
	create_and_connect_timer()
	pass

func _physics_process(delta):
	transform.basis = transform.basis.orthonormalized()
	transform.basis = transform.basis.slerp(target_basis, 0.005)
	pass


func _on_timer_timeout():
	create_and_connect_timer()
	var animation = ["tail_wag", "tail_wag2"].pick_random()
	var animation_player: AnimationPlayer = get_node("AnimationPlayer")
	animation_player.play(animation)
	if randf() >= 0.5:
		target_basis = initial_basis.rotated(game_data.GENERATION_VECTORS.pick_random(), deg_to_rad(global_data.get_randi(0,20)))
	pass


func create_and_connect_timer():
	var timer = get_tree().create_timer(global_data.get_randi(5, 30), false, true, false)
	timer.connect("timeout", _on_timer_timeout)
	pass
