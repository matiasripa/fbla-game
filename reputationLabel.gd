extends Label

func _ready() -> void:
	Global.changeLabels.connect(update)

func update() -> void:
	var duration : float
	var reputationChange = Global.reputation - Global.lastReputation
	if reputationChange != 0:
		if reputationChange < 50:
			duration = 1.0
		else:
			duration = 3.0
		var elapsedTime := 0.0
		var startValue : int = Global.reputation - reputationChange
		var endValue : int = Global.reputation
		
		print("start value: " + str(startValue))
		print("end value: " + str(endValue))
		while elapsedTime < duration:
			text = "Reputation: " + str(round(lerp(startValue, endValue, elapsedTime/duration)))
			await get_tree().process_frame
			elapsedTime += get_process_delta_time()
	text = "Reputation: " + str(Global.reputation)
	Global.lastReputation = Global.reputation
	
	if Global.reputation >= 50:
		add_theme_color_override("font_color", Color(0, 1, 0))  # Green
	elif Global.reputation >= 30:
		add_theme_color_override("font_color", Color(1, 1, 0))  # Yellow
	else:
		add_theme_color_override("font_color", Color(1, 0, 0))  # Red
