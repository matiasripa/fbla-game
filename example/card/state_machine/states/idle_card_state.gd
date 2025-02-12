extends CardState


func _enter():

	card.label.text = "Idle"
	card.pivot_offset = Vector2.ZERO


func on_mouse_entered():
	transitioned.emit("hover")
