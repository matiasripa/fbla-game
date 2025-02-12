extends CardState


func _enter():
	card.label.text = "Release"

	var field_areas = card.drop_point_detector.get_overlapping_areas()
	
	if field_areas.is_empty():
		card.home_field.return_card_starting_position(card)
	else:
		var new_field = field_areas[0].get_parent() as Field
		
		if new_field.name == "destroy":
			card.destroy()  # Call destroy directly when dropped in destroy field
		elif field_areas[0].get_parent() == card.home_field || new_field.isevent || new_field.iswithdraw:
			card.home_field.card_reposition(card)
		else:
			new_field.set_new_card(card)

	transitioned.emit("idle")
