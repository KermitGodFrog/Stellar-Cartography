extends Node
#used mostly to trigger objectives. just takes in a whole lot of updates which would be too expensive/too often to pass through dialogueManager and responds to em
#game.gd not allowed to use speak()

func speak(calling: Node, incoming_wID: String, incoming_value: Variant = null) -> void:
	pass
