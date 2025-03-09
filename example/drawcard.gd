extends Button

func _ready():
	pressed.connect(_on_pressed)  # Connect button press signal
	_update_button_state()  # Initial button state update

func _process(_delta):
	_update_button_state()  # Update button state each frame

# Enable/disable button based on game conditions
func _update_button_state():
	# Find the Signalbus node using a more reliable method
	var signalbus = find_signalbus()
	
	if !signalbus:
		# If not found, disable button and exit function
		disabled = true
		return
	
	# If found, continue with normal logic
	var hand_holder = get_node_or_null("../hand/CardsHolder")
	
	if !hand_holder:
		disabled = true
		return
		
	disabled = !signalbus.is_player_turn or signalbus.actions_this_turn >= signalbus.MAX_ACTIONS_PER_TURN or hand_holder.get_child_count() >= 5

# Handle button press
func _on_pressed():
	var signalbus = find_signalbus()
	if !signalbus:
		return
		
	var hand_holder = get_node_or_null("../hand/CardsHolder")
	if !hand_holder:
		return
		
	if signalbus.is_player_turn and signalbus.actions_this_turn < signalbus.MAX_ACTIONS_PER_TURN:
		if hand_holder.get_child_count() < 5:
			signalbus.track_action()  # Count this as player action
			
			# Safely play sound if it exists
			var audio_player = get_node_or_null("../../../AudioStreamPlayer")
			if audio_player and audio_player.has_method("play2"):
				audio_player.play2()  # Play sound effect
			
			print("Cards drawn")
		else:
			print("Hand is full! Maximum 5 cards allowed.")
	else:
		print("No actions remaining this turn!")

# More reliable method to find the Signalbus
func find_signalbus():
	# First check common paths
	var paths_to_try = [
		"/root/Game/Signalbus",
		"/root/example/Signalbus",
		"/root/Node/Signalbus" # Generic case if scene name changed
	]
	
	for path in paths_to_try:
		var node = get_node_or_null(path)
		if node:
			return node
	
	# If not found by path, try to find by name in the scene tree
	var root = get_tree().root
	return find_node_by_name_recursive(root, "Signalbus")

# Recursive function to find a node by name in the tree
func find_node_by_name_recursive(node, name):
	if node.name == name:
		return node
	
	for child in node.get_children():
		var found = find_node_by_name_recursive(child, name)
		if found:
			return found
	
	return null
