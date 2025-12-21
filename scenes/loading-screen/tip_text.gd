extends Label

const tips = [
	"To quick-orbit a body, right click on it in the SYSTEM LIST.",
	"If you don't find ways to repair while exploring, you will always gain hull deterioration before reaching the next civilized system.",
	"Click on a body on the SYSTEM MAP to quick-lock.",
	"Right click on a body on the SYSTEM MAP to quick-orbit.",
	"Note the 'MARKET PRICE' at all space stations in a system before selling your exploration data.",
	"It is easier to find bodies around the smaller leftward main sequence stars (M,K,G,F,A,B,O).",
	"Extra nanites are paid for the discovery of bodies around larger rightward main sequence stars (M,K,G,F,A,B,O)."
]

func _ready() -> void:
	set_text(tips.pick_random())
	pass
