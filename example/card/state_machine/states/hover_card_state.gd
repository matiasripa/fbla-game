extends CardState

func _enter():
	card.label.text = "HOVER"

func on_gui_input(event: InputEvent):
	# Only allow right-click in withdraw field
	if card.home_field.iswithdraw:
		if event.is_action_pressed("mouse_right"):
			var signalbus = card.get_node("/root/Game/Signalbus")
			if signalbus.is_player_turn and signalbus.actions_this_turn < signalbus.MAX_ACTIONS_PER_TURN:
				signalbus.track_action()
				card.turn -= 1
				card.turn_label.text = str(card.turn) + " turns"
				if card.turn <= 0:
					card.destroy()
	# For other fields (not withdraw or assets), allow left-click to pick up
	elif not card.home_field.isasset:
		if event.is_action_pressed("mouse_left"):
			card.pivot_offset = card.get_global_mouse_position() - card.global_position
			transitioned.emit("Click")

func on_mouse_exited():
	transitioned.emit("Idle")
