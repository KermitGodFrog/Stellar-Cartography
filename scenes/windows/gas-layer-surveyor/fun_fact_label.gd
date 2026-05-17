extends RichTextLabel

const facts: Array = [
	"Balls"
	
	
	
	
	
	
]




func generate_new_fact() -> void:
	clear()
	append_text("[i]FUN FACT:[/i][p]%s[/p]" % facts.pick_random())
	pass
