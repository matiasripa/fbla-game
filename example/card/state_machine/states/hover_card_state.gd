extends CardState

func _enter():
	card.label.text = "HOVER"

func on_gui_input(event: InputEvent):
	if event.is_action_pressed("mouse_left"):
		card.pivot_offset = card.get_global_mouse_position() - card.global_position
		transitioned.emit("Click")
	elif event.is_action_pressed("mouse_right") and card.home_field.iswithdraw:
		var signalbus = card.get_node("/root/Game/Signalbus")
		if signalbus.is_player_turn and signalbus.actions_this_turn < signalbus.MAX_ACTIONS_PER_TURN:
			card.turn -= 1
			card.turn_label.text = str(card.turn) + " turns"
			signalbus.track_action()
			if card.turn <= 0:
				card.queue_free()

func on_mouse_exited():
	transitioned.emit("Idle")
