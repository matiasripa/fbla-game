extends CardState

func _enter():
	card.label.text = "HOVER"

func get_signalbus():
	# First try using the parent of home_field, which is likely the scene root
	var parent_scene = card.home_field.get_parent()
	if parent_scene and parent_scene.has_node("Signalbus"):
		return parent_scene.get_node("Signalbus")
	
	# If that fails, look through all root children
	var root = card.get_tree().root
	for child in root.get_children():
		if child.has_node("Signalbus"):
			return child.get_node("Signalbus")
		# Or if the child itself is Signalbus
		if child.name == "Signalbus":
			return child
	
	# If still not found, try to find it recursively in the scene
	return card.get_tree().current_scene.find_child("Signalbus", true, false)

func on_gui_input(event: InputEvent):
	# Only allow right-click in withdraw field
	if card.home_field.iswithdraw:
		if event.is_action_pressed("mouse_right"):
			var signalbus = get_signalbus()
			if signalbus and signalbus.is_player_turn and signalbus.actions_this_turn < signalbus.MAX_ACTIONS_PER_TURN:
				signalbus.track_action()
				card.turn -= 1
				card.turn_label.text = str(card.turn) + ""
				if card.turn <= 0:
					card.destroy()
			elif signalbus == null:
				print("Warning: Signalbus not found")
	# For other fields (not withdraw or assets), allow left-click to pick up
	elif not card.home_field.isasset:
		if event.is_action_pressed("mouse_left"):
			card.pivot_offset = card.get_global_mouse_position() - card.global_position
			transitioned.emit("Click")

func on_mouse_exited():
	transitioned.emit("Idle")
