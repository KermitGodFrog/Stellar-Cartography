extends bodyAPI
class_name circularBodyAPI

@export var radius: float
@export var mass: float
@export var surface_color: Color
#@export var surface_texture_pointer

#to inherit this, the class must contain original methods or variables which are
#A: of a type which you would feel unsafe cramming into metadata - e.g, object or texture
#B: are modified constantly during gameplay
