# In clicked_card_state.gd
extends CardState

func _enter():
	card.label.text = "CLICKED"



func on_input(event):
	if event is InputEventMouseMotion:
		transitioned.emit("Drag")
