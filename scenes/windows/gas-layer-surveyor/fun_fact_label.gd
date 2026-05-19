extends RichTextLabel

const facts: Array = [
	"Saturn has an average radius of about nine times that of Old Earth.",
	"A day on Jupiter lasts roughly ten hours - the shortest day in the (long lost) Sol system.",
	"A gas giant is a really big planet made out of gas. Both Neptunian and Jovian worlds are considered gas giants.",
	"Gas giants can have a rocky core, but a majority of their mass is in the gas surrounding it.",
	"The four gas giants in the Sol system are Jupiter, Saturn, Uranus and Neptune."
]

func generate_new_fact() -> void:
	clear()
	append_text("[i]FUN FACT:[/i][p]%s[/p]" % facts.pick_random())
	pass
