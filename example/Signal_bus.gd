extends Node
@onready var assets = $CanvasLayer/Assets
@onready var withdraw = $CanvasLayer/Withdraw










func _on_end_turn_pressed() -> void:
	assets.end_turn()
	withdraw.end_turn()




func _on_assets_transfercard(card: Variant) -> void:
	withdraw.set_new_card(card)
	pass # Replace with function body.
