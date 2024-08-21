extends Node

@onready var play_timer = $play_timer
@onready var music = $music

#needs to duck for dialogue!

func _ready():
	play_timer.start(global_data.get_randi(60, 360))
	pass

func _on_play_timer_timeout():
	$music.play()
	play_timer.start(global_data.get_randi(60, 360))
	pass
