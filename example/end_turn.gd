extends Button

signal endturn  # Signal to emit when turn ends

func _ready() -> void:
	_update_button_state()  # Initialize button state

func _process(_delta) -> void:
	_update_button_state()  # Update button state every frame

# Enable/disable button based on game state
func _update_button_state() -> void:
	var assets = get_node("../Assets")
	var withdraw = get_node("../Withdraw")
	
	var valid_assets = false
	var valid_withdraw = false
	
	# Check for valid cards in Assets field
	for card in assets.get_node("CardsHolder").get_children():
		if not card.is_queued_for_deletion() and not card.tween_destroy:
			valid_assets = true
			break
			
	# Check for valid cards in Withdraw field
	for card in withdraw.get_node("CardsHolder").get_children():
		if not card.is_queued_for_deletion() and not card.tween_destroy:
			valid_withdraw = true
			break
	
	# Button is disabled if either field is empty
	disabled = not (valid_assets or valid_withdraw)

# Handle button press
func _on_pressed() -> void:
	if not disabled:
		$"../../AudioStreamPlayer2".play()
		endturn.emit()  # Emit end turn signal
