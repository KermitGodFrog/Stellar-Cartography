extends Node3D

@onready var world_environment = $world_environment
@onready var no_current_planet_bg = $camera_offset/camera/canvas_layer/no_current_planet_bg
@onready var press_to_start = $camera_offset/camera/canvas_layer/press_to_start_button

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
	},
	"blue-fast": {
		"bg_color": Color("6192ff"),
		"bg_time_divisor": 30.0,
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/blue_fast.tres"),
		"fog_albedo": Color("83a6f6"),
	},
	"green-bacterium": {
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/bg_bacterium.tres"),
		"fog_albedo": Color("00610e"),
		"fog_emission": Color("00803c")
	},
	"pink-cells": {
		"bg_color": Color("9801fd"),
		"bg_time_divisor": 150,
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/pink_cells.tres"),
		"fog_albedo": Color("ae00a4"),
		"fog_length": 15.0
	}
}

var current_planet: planetBodyAPI = null

var current_layer: String = "default"
var target_color: Color = Color.WHITE

var awaiting_start: bool = true
var depth: float = 0.0

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
					#target_time_divisor = value
					shader_material.set_shader_parameter("time_divisor", value)
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
	if not awaiting_start:
		depth += delta
	
	var shader_material = world_environment.get_environment().get_sky().get_material()
	var current_color = shader_material.get_shader_parameter("color") as Color
	shader_material.set_shader_parameter("color", current_color.lerp(target_color, delta))
	pass



func _on_current_planet_changed(new_planet : planetBodyAPI):
	if current_planet != new_planet:
		no_current_planet_bg.hide()
		current_planet = new_planet
		
		press_to_start.show()
		awaiting_start = true
		
#		var layers = new_planet.get_gas_layers_sum()
		
		#construct layer distances
		#put them on the depth indicator (not made yet)
		#profit
		
		
		
		
		
		
	pass

func finish() -> void: #called when depth is at the max or above the max
	awaiting_start = true
	depth = float()
	pass

func _on_current_planet_cleared():
	finish()
	no_current_planet_bg.show()
	press_to_start.hide()
	#put on the black screen + prevent player from EVER doing the minigame again for this planet, or from picking the gas layers 
	
	pass









func _on_gas_layer_surveyor_window_close_requested() -> void:
	owner.hide()
	pass


func _on_press_to_start_button_pressed() -> void:
	press_to_start.hide()
	awaiting_start = false
	pass
