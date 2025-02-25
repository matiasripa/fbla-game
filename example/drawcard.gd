extends Button

func _ready():
	pressed.connect(_on_pressed)  # Connect button press signal
	_update_button_state()  # Initial button state update

func _process(_delta):
	_update_button_state()  # Update button state each frame

# Enable/disable button based on game conditions
func _update_button_state():
	var signalbus = get_node("/root/Game/Signalbus")
	# Disable button if:
	# - Not player's turn
	# - Max actions per turn reached
	# - Hand is full (5 cards max)
	disabled = !signalbus.is_player_turn or signalbus.actions_this_turn >= signalbus.MAX_ACTIONS_PER_TURN or get_node("../hand/CardsHolder").get_child_count() >= 5

# Handle button press
func _on_pressed():
	var signalbus = get_node("/root/Game/Signalbus")
	if signalbus.is_player_turn and signalbus.actions_this_turn < signalbus.MAX_ACTIONS_PER_TURN:
		if get_node("../hand/CardsHolder").get_child_count() < 5:
			signalbus.track_action()  # Count this as player action
			$"../../../AudioStreamPlayer".play2()  # Play sound effect
			print("Cards drawn")
		else:
			print("Hand is full! Maximum 5 cards allowed.")
	else:
		print("No actions remaining this turn!")
