extends CardState


func _enter():
	card.label.text = "DRAG"
	card.update_highlight_state(true)

	# Make sure to remove any zoom card when entering drag state
	if card.zoom_active:
		card.remove_zoom_card()
	
	card.index = card.get_index()
	
	var canvas_layer := get_tree().get_first_node_in_group("fields")
	if canvas_layer:
		card.reparent(canvas_layer)


func on_input(event: InputEvent):
	var mouse_motion := event is InputEventMouseMotion
	var confirm = event.is_action_released("mouse_left")
	
	if mouse_motion:
		card.global_position = card.get_global_mouse_position() - card.pivot_offset
	
	if confirm:
		get_viewport().set_input_as_handled()
		transitioned.emit("Release")
func _exit():
	# Turn off highlight when exiting drag state
	card.update_highlight_state(false)
