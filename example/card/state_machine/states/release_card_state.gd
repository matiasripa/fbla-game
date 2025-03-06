extends CardState

func _enter():
	card.label.text = "Release"
	
	# Ensure any zoom card is removed when releasing
	if card.zoom_active:
		card.remove_zoom_card()
		
	var field_areas = card.drop_point_detector.get_overlapping_areas()
	
	if field_areas.is_empty():
		card.home_field.return_card_starting_position(card)
	else:
		var new_field = field_areas[0].get_parent() as Field
		
		if new_field.name == "destroy":
			card.destroy()
			return
		
		# Check if card must go to assets first
		if card.must_go_to_assets and new_field.name != "Assets" and card.home_field.name != "Assets":
			print("This card must be placed in Assets field first!")
			card.home_field.return_card_starting_position(card)
		elif field_areas[0].get_parent() == card.home_field || new_field.isevent || (new_field.iswithdraw and !card.is_positive_phase):
			card.home_field.card_reposition(card)
		else:
			if new_field.name == "Assets":
				card.must_go_to_assets = false
			new_field.set_new_card(card)


	transitioned.emit("idle")
