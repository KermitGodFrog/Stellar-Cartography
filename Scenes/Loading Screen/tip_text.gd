extends Label

const tips = [
	"To quick-orbit a body, right click on it in the SYSTEM LIST.",
	"If you don't find ways to repair while exploring, you will always gain hull deterioration before reaching the next civilized system."
	
	
	
	
	
]


func _ready() -> void:
	set_text(tips.pick_random())
	pass
