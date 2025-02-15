extends Button

signal endturn

func _ready() -> void:
	_update_button_state()

func _process(_delta) -> void:
	_update_button_state()

func _update_button_state() -> void:
	var assets = get_node("../Assets")
	var withdraw = get_node("../Withdraw")
	
	var valid_assets = true # orignally false because it breaks if you destroy all cards in your hand
	var valid_withdraw = false
	
	for card in assets.get_node("CardsHolder").get_children():
		if not card.is_queued_for_deletion() and not card.tween_destroy:
			valid_assets = true
			break
			
	for card in withdraw.get_node("CardsHolder").get_children():
		if not card.is_queued_for_deletion() and not card.tween_destroy:
			valid_withdraw = true
			break
	
	disabled = not (valid_assets or valid_withdraw)

func _on_pressed() -> void:
	if not disabled:
		endturn.emit()
