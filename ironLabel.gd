extends Label

func _ready() -> void:
	Global.changeLabels.connect(update)

func update() -> void:
	var duration : float
	var ironChange = Global.iron - Global.lastIron
	if ironChange != 0:
		if ironChange < 50:
			duration = 1.0
		else:
			duration = 3.0
		var elapsedTime := 0.0
		var startValue : int = Global.iron - ironChange
		var endValue : int = Global.iron
		
		print("start value: " + str(startValue))
		print("end value: " + str(endValue))
		while elapsedTime < duration:
			text = "Iron: " + str(round(lerp(startValue, endValue, elapsedTime/duration)))
			await get_tree().process_frame
			elapsedTime += get_process_delta_time()
	text = "Iron: " + str(Global.iron)
	Global.lastIron = Global.iron
	
	if Global.iron >= 50:
		add_theme_color_override("font_color", Color(0, 1, 0))  # Green
	elif Global.iron >= 30:
		add_theme_color_override("font_color", Color(1, 1, 0))  # Yellow
	else:
		add_theme_color_override("font_color", Color(1, 0, 0))  # Red
