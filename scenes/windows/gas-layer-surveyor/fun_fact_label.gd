extends RichTextLabel

const facts: Array = [
	#Lunar and Planetary Institute: All About the Gas Giants --- https://www.lpi.usra.edu/education/space_days/activities/gasGiants/aboutGasGiants.pdf --- Retrieved 17/5/26
	"The four gas giants in our solar system are Neptune, Uranus, Saturn, and Jupiter. These are also called the Jovian planets.",
	"'Jovian planet' refers to the Roman god Jupiter and was intended to indicate that all of the Jovian planets were similar to Jupiter.",
	"Jupiter is about 11 times the diameter of Earth, Saturn 9 times, and Uranus and Neptune about 4 times Earth’s diameter.",
	"A gas giant is a GIANT planet that is made of gas! They are different from rocky or terrestrial planets that are made of mostly rock.",
	"Unlike rocky planets, gas giants do not have a well-defined surface – there is no clear boundary between where the atmosphere ends and the surface starts!",
	"Gas giants have atmospheres that are (usually) mostly hydrogen and helium.",
	"All four Jovian planets rotate relatively rapidly – while Earth spins once on its axis every 24 hours, Saturn spins once every 10 hours.",
	"Like Earth, all the Jovian planets have wind bands. These are seen as east-west stripes. Jupiter has the most well defined bands.",
	"Gas giants may have a rocky or metallic core but the majority of their mass is in the form of gas (or gas compressed into a liquid state – to get an idea of what this could be like, think of liquid mercury in a thermometer).",
	"Jupiter and Saturn probably have liquid metallic hydrogen interiors (liquid hydrogen conducts electricity).",
	"Scientists believe Uranus and Neptune have interiors that contain a mixture (or layers) of rock, water, methane, and ammonia.",
	"All four Jovian planets have rings and moons. Saturn's rings, made of mostly ice, are the most spectacular, and the only ones known before the 1970s. As of 2004, Jupiter was thought to have the most moons, with more than sixty discovered!",
	#BBC: What are the gas planets? --- https://www.bbc.co.uk/bitesize/articles/zmycg7h#zk444xs --- Retrieved 17/5/26
	"Apparently, Jupiter has the shortest day in the Sol system, only lasting ten hours. If we knew where the Sol system was after the Late Proliferation era, we would be able to confirm that fact!", #heavily modified
	"Jupiter is twice as massive as all of the other planets in the Sol system combined.",
	"Saturn is nine times wider than Earth.",
	"Uranus was first discovered by astronomer William Herschel in 1781.",
	"Uranus has two sets of rings. The inner system has nine dark grey rings and the outer system is made up of 2 rings; 1 which is reddish coloured and the other which is blue.",
	"Neptune is about four times wider than Earth.",
	"Jupiter doesn’t have a surface, as it's made up of a mix of gases and liquids.",
]

func generate_new_fact() -> void:
	clear()
	append_text("[i]FUN FACT:[/i][p]%s[/p]" % facts.pick_random())
	pass
