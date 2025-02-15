extends CardState

func _enter():
	card.label.text = "Release"
	var field_areas = card.drop_point_detector.get_overlapping_areas()
	
	if field_areas.is_empty():
		card.home_field.return_card_starting_position(card)
		card.smooth_move_to(card.get_parent().global_position)
	else:
		var new_field = field_areas[0].get_parent() as Field
		
		if new_field.name == "destroy":
			card.destroy()
			return
		
		# Check if card must go to assets first
		if card.must_go_to_assets and new_field.name != "Assets" and card.home_field.name != "Assets":
			print("This card must be placed in Assets field first!")
			card.home_field.return_card_starting_position(card)
			card.smooth_move_to(card.get_parent().global_position)
		elif field_areas[0].get_parent() == card.home_field || new_field.isevent || (new_field.iswithdraw and !card.is_positive_phase):
			card.home_field.card_reposition(card)
			card.smooth_move_to(card.get_parent().global_position)
		else:
			if new_field.name == "Assets":
				card.must_go_to_assets = false
			new_field.set_new_card(card)
			card.smooth_move_to(card.get_parent().global_position)

	transitioned.emit("idle")
