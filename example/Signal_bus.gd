extends Node
@onready var assets = $CanvasLayer/Assets
@onready var withdraw = $CanvasLayer/Withdraw
@onready var action_label = $CanvasLayer/ActionLabel

var is_player_turn: bool = true
var actions_this_turn: int = 0
const MAX_ACTIONS_PER_TURN = 2

func _ready():
	reset_turn()
	update_action_label()

func reset_turn():
	is_player_turn = true
	actions_this_turn = 0
	update_action_label()
	
func check_end_turn():
	if actions_this_turn >= MAX_ACTIONS_PER_TURN:
		end_turn()

func end_turn():
	actions_this_turn = 0
	assets.end_turn()
	withdraw.end_turn()
	is_player_turn = true
	update_action_label()

func track_action():
	if is_player_turn:
		actions_this_turn += 1
		update_action_label()
		check_end_turn()

func update_action_label():
	action_label.text = "Actions remaining: " + str(MAX_ACTIONS_PER_TURN - actions_this_turn)

func _on_end_turn_pressed() -> void:
	end_turn()

func _on_assets_transfercard(card: Variant) -> void:
	withdraw.set_new_card(card)
