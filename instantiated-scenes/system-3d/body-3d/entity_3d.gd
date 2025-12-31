extends Sprite3D

@onready var large_texture = preload("uid://c236x4bwtcifq")
@onready var small_texture = preload("uid://kxo1pkvmhml4")

var identifier: int

func get_identifier():
	return identifier
func set_identifier(new_identifier: int):
	identifier = new_identifier
	pass

func initialize(_pixel_size: float):
	set_pixel_size(_pixel_size)
	pass

func updatePosition(pos: Vector3):
	position = pos
	pass

func _on_scope_mode_changed(new_mode: playerAPI.SCOPE_MODES) -> void:
	match new_mode:
		playerAPI.SCOPE_MODES.VIS:
			set_texture(small_texture)
		playerAPI.SCOPE_MODES.RAD:
			set_texture(large_texture)
	pass
