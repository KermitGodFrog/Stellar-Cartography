extends Node3D

signal state_changed(new_state: STATES)

@onready var world_environment = $world_environment
@onready var no_current_planet_bg = $camera_offset/camera/control/no_current_planet_bg
@onready var press_to_start = $camera_offset/camera/control/press_to_start_button
@onready var depth_indicator = $camera_offset/camera/control/depth_margin/depth_panel/depth_indicator
@onready var selection_screen = $camera_offset/camera/control/selection_screen
@onready var speed_lines = $speed_lines

const layer_data = { #name (color(s)-noise-property): properties
	"default": {
		"bg_color": Color.WHITE,
		"bg_time_divisor": 100.0,
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/bg_default.tres"),
		"fog_albedo": Color.WHITE,
		"fog_emission": Color.BLACK,
		"fog_density": 0.035,
		"fog_anisotropy": 0.6,
		"fog_length": 30.0
	},
	"red-pink-splotches": {
		"bg_color": Color.RED,
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/bg_splotches.tres"),
		"fog_albedo": Color("ff5df0"),
		"fog_emission": Color("0000ba"),
		"fog_length": 15.0
	},
	"yellow-orange-splotches": {
		"bg_color": Color.YELLOW,
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/bg_splotches.tres"),
		"fog_albedo": Color("d16600"),
		"fog_emission": Color.RED,
	},
	"green-splotches-slow": {
		"bg_color": Color.GREEN,
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/bg_splotches.tres"),
		"bg_time_divisor": 180.0,
		"fog_albedo": Color("254925"),
	},
	"green-splotches-fast": {
		"bg_color": Color.GREEN,
		"bg_time_divisor": 50.0,
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/bg_splotches.tres"),
		"fog_albedo": Color("60aa60"),
		"fog_emission": Color("00006b")
	},
	"blue-splotches": {
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/bg_splotches.tres"),
		"fog_albedo": Color("008388"),
		"fog_emission": Color("2e69ff")
	},
	"red-bacterium-slow": {
		"bg_color": Color("ff3f30"),
		"bg_time_divisor": 150.0,
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/bg_bacterium.tres"),
		"fog_albedo": Color("330000"),
		"fog_emission": Color("800000"),
		"fog_density": 0.05
	},
	"red-blue-bacterium-fast": {
		"bg_color": Color("ff3f30"),
		"bg_time_divisor": 50.0,
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/bg_bacterium.tres"),
		"fog_albedo": Color("1c1c5b"),
		"fog_emission": Color("000068"),
		"fog_density": 0.05
	},
	"blue-bacterium": {
		"bg_color": Color.BLUE,
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/bg_bacterium.tres"),
		"fog_albedo": Color.BLACK,
		"fog_emission": Color("00004d")
	},
	"purple-bacterium": {
		"bg_color": Color("4e00ff"),
		"bg_time_divisor": 70.0,
		"bg_sampler": preload("res://Scenes/Gas Layer Surveyor/bg_bacterium.tres"),
		"fog_albedo": Color("002b2b"),
		"fog_emission": Color("27007d")
	}
}

var current_planet: planetBodyAPI = null

var current_offsets: PackedFloat32Array = []
var current_layers: PackedStringArray = []

var active_layer: String = "default"
var checkpoint: int = 0
var target_color: Color = Color.WHITE

enum STATES {WAITING, SURVEYING, SELECTING, INVALID}
var state: STATES = STATES.INVALID:
	set(value):
		state = value
		emit_signal("state_changed", state)

var depth: float = 0.0
const MAX_DEPTH: float = 30.0
const MINIMUM_OFFSET: float = 2.5



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
		active_layer = layer_name
		for p in properties:
			var value = properties.get(p)
			match p:
				"bg_color":
					target_color = value
				"bg_time_divisor":
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

func get_active_layer() -> String:
	return active_layer



func _ready() -> void:
	state_changed.connect(_on_state_changed)
	selection_screen._layer_data = layer_data
	state = STATES.INVALID
	apply_new_layer()
	pass

func _process(delta: float) -> void:
	match state:
		STATES.SURVEYING:
			depth += delta
			depth_indicator.set_value(remap(depth, 0.0, MAX_DEPTH, 0.0, 100.0))
			if checkpoint < current_offsets.size():
				if depth > current_offsets[checkpoint]:
					apply_new_layer(current_layers[checkpoint])
					checkpoint += 1
			if depth >= MAX_DEPTH:
				state = STATES.SELECTING
	
	
	
	#graphics
	var shader_material = world_environment.get_environment().get_sky().get_material()
	var current_color = shader_material.get_shader_parameter("color") as Color
	shader_material.set_shader_parameter("color", current_color.lerp(target_color, delta))
	pass



func _on_current_planet_changed(new_planet : planetBodyAPI):
	if current_planet != new_planet:
		state = STATES.WAITING #has to be first or current_planet will be set to null
		current_planet = new_planet
		
		var layers = new_planet.get_gas_layers_sum()
		
		var optimal_distance = MAX_DEPTH / layers
		
		var offsets: PackedFloat32Array = []
		for l in layers: offsets.append(optimal_distance * l)
		offsets.append(MAX_DEPTH)
		
		for i_ in offsets.size(): #forwards pass
			if (i_ < offsets.size() - 1) and (i_ != 0):
				var o = offsets[i_] #lower
				var next = offsets[i_ + 1] #higher
				var new = clampf(global_data.get_randf(o, next), o, next - MINIMUM_OFFSET)
				offsets.set(i_, new)
		for _i in offsets.size(): #backwards pass
			if (_i > 0) and (_i != offsets.size() - 1):
				var previous = offsets[_i - 1] #lower
				var o = offsets[_i] #higher
				var new = clampf(global_data.get_randf(previous, o), previous + MINIMUM_OFFSET, o)
				offsets.set(_i, new)
		
		offsets.remove_at(offsets.size() - 1) #remove MAX_DEPTH from PackedFloat32Array
		
		current_offsets = offsets
		print("CURRENT OFFSETS: ", current_offsets)
		
		var gradient = Gradient.new()
		gradient.set_interpolation_mode(Gradient.GRADIENT_INTERPOLATE_CONSTANT)
		var remapped = Array(offsets).map(func(o): return remap(o, 0.0, MAX_DEPTH, 0.0, 1.0))
		gradient.set_color(1, Color.BLACK) #auto generates with two offsets and two colors - offsets: [0, 1] , colors: [Color.BLACK, Color.WHITE]
		
		for o in remapped:
			gradient.add_point(o, Color.WHITE)
			gradient.add_point(o + (1.0 / 100.0), Color.BLACK)
		
		var texture = GradientTexture1D.new()
		texture.set_gradient(gradient)
		depth_indicator.set_under_texture(texture)
		
		var reduced_layer_keys = layer_data.keys().duplicate()
		reduced_layer_keys.erase("default")
		for i in current_offsets.size():
			var key = reduced_layer_keys.pick_random()
			current_layers.append(key)
			reduced_layer_keys.erase(key)
	pass

func _on_current_planet_cleared():
	if current_planet != null:
		current_planet.metadata["missing_GL"] = false
	state = STATES.INVALID
	pass



func _on_state_changed(new_state: STATES) -> void:
	no_current_planet_bg.visible = new_state == STATES.INVALID
	press_to_start.visible = new_state == STATES.WAITING
	selection_screen.visible = new_state == STATES.SELECTING
	speed_lines.emitting = new_state == STATES.SURVEYING
	
	match new_state:
		STATES.INVALID:
			current_planet = null
			depth = float()
		STATES.WAITING:
			depth = float()
		STATES.SURVEYING:
			pass
		STATES.SELECTING:
			selection_screen.initialize(current_layers)
			depth = float()
	pass

func _on_press_to_start_button_pressed() -> void:
	state = STATES.SURVEYING
	pass

func _on_gas_layer_surveyor_window_close_requested() -> void:
	_on_current_planet_cleared()
	owner.hide()
	pass
