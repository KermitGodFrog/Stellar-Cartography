extends Node3D

@onready var world_environment = $world_environment

const layer_data = { #name: properties
	"default": {
		"bg_color": Color.WHITE,
		"bg_time_divisor": 100.0,
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/bg_simple.tres"),
		"fog_albedo": Color.WHITE,
		"fog_emission": Color.BLACK,
		"fog_density": 0.035,
		"fog_anisotropy": 0.6,
		"fog_length": 30.0
	},
	"yellow-basic": {
		"bg_color": Color("ff8000"), 
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/bg_ping_pong.tres"), 
		"fog_albedo": Color("ffc98a"), 
		"fog_emission": Color("ffa500"),
	},
	"blue-fast": {
		"bg_color": Color("6192ff"),
		"bg_time_divisor": 30.0,
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/blue_fast.tres"),
		"fog_albedo": Color("83a6f6"),
	},
	"green-bacterium": {
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/bg_bacterium.tres"),
		"fog_albedo": Color("00dd2e"),
		"fog_emission": Color("00803c")
	}
}

var current_layer: String = "default"

var target_color: Color = Color.WHITE
var target_time_divisor: float = 100.0

func apply_new_layer(layer_name: String = "default") -> void: #default is always applied first, allowing 'carving' of properties from the base
	if not layer_name == "default":
		set_layer_values() #reset to default
		set_layer_values(layer_name)
	else:
		set_layer_values() #reset to default
	pass

func set_layer_values(layer_name: String = "default") -> void: 
	var environment = world_environment.get_environment()
	var shader_material = environment.get_sky().get_material()
	
	var properties = layer_data.get(layer_name)
	if properties != null:
		current_layer = layer_name
		for p in properties:
			var value = properties.get(p)
			match p:
				"bg_color":
					target_color = value
				"bg_time_divisor":
					target_time_divisor = value
				"bg_sampler":
					shader_material.set_shader_parameter("sampler", value)
				"fog_albedo":
					environment.set("volumetric_fog_albedo", value)
				"fog_emission":
					environment.set("volumetric_fog_emission", value)
				"fog_density":
					environment.set("volumetric_fog_density", value)
				"fog_anisotropy":
					environment.set("volumetric_fog_anisotropy", value)
				"fog_length":
					environment.set("volumetric_fog_length", value)
	pass

func get_current_layer() -> String:
	return current_layer

func _ready() -> void:
	apply_new_layer()
	pass

func _process(delta: float) -> void:
	var shader_material = world_environment.get_environment().get_sky().get_material()
	
	var current_color = shader_material.get_shader_parameter("color") as Color
	var current_time_divisor = shader_material.get_shader_parameter("time_divisor") as float
	
	shader_material.set_shader_parameter("color", current_color.lerp(target_color, delta))
	shader_material.set_shader_parameter("time_divisor", lerpf(current_time_divisor, target_time_divisor, delta))
	pass





func _on_popup() -> void:
	pass
