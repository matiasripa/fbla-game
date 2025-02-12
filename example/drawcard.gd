extends Button

func _ready():
	# Connect to button press
	pressed.connect(_on_pressed)

func _on_pressed():
	var signalbus = get_node("/root/Game/Signalbus")
	if signalbus.is_player_turn and signalbus.actions_this_turn < signalbus.MAX_ACTIONS_PER_TURN:
		if get_node("../hand/CardsHolder").get_child_count() < 5:
			signalbus.track_action()
		else:
			print("Hand is full! Cannot draw more cards.")
