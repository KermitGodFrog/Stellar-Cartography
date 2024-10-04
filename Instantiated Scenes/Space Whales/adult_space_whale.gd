extends Node3D

var initial_basis: Basis
var target_basis: Basis


func _ready():
	create_and_connect_timer()
	pass

func _physics_process(_delta):
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

func get_positions() -> PackedVector3Array:
	var positions: PackedVector3Array = []
	#var skeleton = get_node("adult_space_whale/Skeleton3D")
	#const bones = ["head1", "right_wing5", "left_wing5", "tail3"]
	#for bone in bones:
		#positions.append(skeleton.to_global(skeleton.get_bone_pose_position(skeleton.find_bone(bone))))
	for child in get_node("adult_space_whale/bounds").get_children():
		positions.append(get_node("adult_space_whale/bounds").to_global(child.position))
	return positions

func is_posing() -> bool:
	if get_node("AnimationPlayer").is_playing(): return true
	else: return false

func get_characteristics() -> int:
	return 0
