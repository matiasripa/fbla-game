extends Label

func _ready() -> void:
	Global.changeLabels.connect(update)

func update() -> void:
	var duration : float
	var moneyChange = Global.money - Global.lastMoney
	if moneyChange != 0:
		if moneyChange < 50:
			duration = 1.0
		else:
			duration = 3.0
		var elapsedTime := 0.0
		var startValue : int = Global.money - moneyChange
		var endValue : int = Global.money
		
		print("start value: " + str(startValue))
		print("end value: " + str(endValue))
		while elapsedTime < duration:
			text = "Money: " + str(round(lerp(startValue, endValue, elapsedTime/duration)))
			await get_tree().process_frame
			elapsedTime += get_process_delta_time()
	text = "Money: " + str(Global.money)
	Global.lastMoney = Global.money
	
	if Global.money >= 50:
		add_theme_color_override("font_color", Color(0, 1, 0))  # Green
	elif Global.money >= 30:
		add_theme_color_override("font_color", Color(1, 1, 0))  # Yellow
	else:
		add_theme_color_override("font_color", Color(1, 0, 0))  # Red
