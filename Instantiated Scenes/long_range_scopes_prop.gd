extends Node3D

var initial_basis: Basis
var target_basis: Basis

@export var size_reward_curve: Curve
@export var distance_reward_curve: Curve
@export var characteristics_reward: int

@export var animation_mean: int
@export var animation_stdev: int
@export var animation_names: Array[String]

@export_node_path("Node3D") var bounds
@export_node_path("AnimationPlayer") var animation_player

func _ready():
	if animation_player:
		create_animation_update_timer()
	pass

func _physics_process(_delta):
	transform.basis = transform.basis.orthonormalized()
	if target_basis:
		transform.basis = transform.basis.slerp(target_basis, 0.005)
	pass

func create_animation_update_timer() -> void:
	var timer = get_tree().create_timer(randfn(animation_mean, animation_stdev), false)
	timer.connect("timeout", _on_update_animation)
	pass

func _on_update_animation() -> void:
	create_animation_update_timer()
	var animation = animation_names.pick_random()
	get_node(animation_player).play(animation)
	pass

func get_positions() -> PackedVector3Array:
	var positions: PackedVector3Array = []
	for child in get_node(bounds).get_children():
		positions.append(get_node(bounds).to_global(child.position))
	return positions

func is_posing() -> bool:
	if animation_player:
		if get_node(animation_player).is_playing(): return true
		else: return false
	else: return false

func get_characteristics() -> int:
	return characteristics_reward
