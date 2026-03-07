extends actor3D

@onready var large_texture = preload("uid://c236x4bwtcifq")
@onready var small_texture = preload("uid://kxo1pkvmhml4")

func _on_scope_mode_changed(_new_mode: playerAPI.SCOPE_MODES) -> void:
	match _new_mode:
		playerAPI.SCOPE_MODES.VIS:
			sprite.set_texture(small_texture)
		playerAPI.SCOPE_MODES.RAD:
			sprite.set_texture(large_texture)
	pass
