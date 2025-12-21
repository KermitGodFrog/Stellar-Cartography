extends RichTextLabel

const max_hide_time: int = 750
var hide_time: int = 0:
	set(value):
		hide_time = maxi(0, value)

func add_entry(entry_text: String, text_color: Color = Color.WHITE):
	hide_time = max_hide_time
	if text_color != Color.WHITE:
		append_text("[color=%s]%s[/color]\n" % [text_color.to_html(), entry_text])
	else:
		append_text(entry_text)
	pass

func clear_entries() -> void:
	clear()
	pass

func _physics_process(delta):
	hide_time -= delta
	set("modulate", Color(1,1,1,remap(hide_time, 0, max_hide_time, 0, 1)))
	pass
