extends Node
@onready var assets = $CanvasLayer/Assets
@onready var withdraw = $CanvasLayer/Withdraw
signal endturn



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_end_turn_pressed() -> void:
	assets.end_turn()
	withdraw.end_turn()
func transfer():#transfers from asset to withdarw
	
	pass


func _on_assets_transfer_card() -> void:
	pass # Replace with function body.
