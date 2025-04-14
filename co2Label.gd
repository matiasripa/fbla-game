extends Label

func _ready() -> void:
	Global.changeLabels.connect(update)

func update() -> void:
	var duration : float
	var co2Change = Global.co2 - Global.lastCo2
	if co2Change != 0:
		if co2Change < 50:
			duration = 1.0
		else:
			duration = 3.0
		var elapsedTime := 0.0
		var startValue : int = Global.co2 - co2Change
		var endValue : int = Global.co2
		
		print("start value: " + str(startValue))
		print("end value: " + str(endValue))
		while elapsedTime < duration:
			text = "CO2: " + str(round(lerp(startValue, endValue, elapsedTime/duration)))
			await get_tree().process_frame
			elapsedTime += get_process_delta_time()
	text = "CO2: " + str(Global.co2)
	Global.lastCo2 = Global.co2
	
	if Global.co2 >= 50:
		add_theme_color_override("font_color", Color(1, 0, 0))  # Red
	elif Global.co2 >= 30:
		add_theme_color_override("font_color", Color(1, 1, 0))  # Yellow
	else:
		add_theme_color_override("font_color", Color(0, 1, 0))  # Green
