extends Button

func _ready():
	pressed.connect(_on_pressed)
	_update_button_state()

func _process(_delta):
	_update_button_state()

func _update_button_state():
	var signalbus = get_node("/root/Game/Signalbus")
	disabled = !signalbus.is_player_turn or signalbus.actions_this_turn >= signalbus.MAX_ACTIONS_PER_TURN or get_node("../hand/CardsHolder").get_child_count() >= 5

func _on_pressed():
	var signalbus = get_node("/root/Game/Signalbus")
	if signalbus.is_player_turn and signalbus.actions_this_turn < signalbus.MAX_ACTIONS_PER_TURN:
		if get_node("../hand/CardsHolder").get_child_count() < 5:
			signalbus.track_action()
			$"../../../AudioStreamPlayer".play2()
			print("Cards drawn")
		else:
			print("Hand is full! Maximum 5 cards allowed.")
	else:
		print("No actions remaining this turn!")
