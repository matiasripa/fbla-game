# In clicked_card_state.gd
extends CardState

func _enter():
	card.label.text = "CLICKED"
	# Turn on the highlight when clicked
	card.update_highlight_state(true)

func _exit():
	# Turn off the highlight when leaving the clicked state
	card.update_highlight_state(false)

func on_input(event):
	if event is InputEventMouseMotion:
		transitioned.emit("Drag")
