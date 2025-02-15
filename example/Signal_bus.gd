extends Node
@onready var assets = $CanvasLayer/Assets
@onready var withdraw = $CanvasLayer/Withdraw
@onready var events = $CanvasLayer/Events
@onready var action_label = $CanvasLayer/ActionLabel
@onready var money_label = $CanvasLayer/MoneyLabel
@onready var co2_label = $CanvasLayer/CO2Label
@onready var iron_label = $CanvasLayer/IronLabel
@onready var reputation_label = $CanvasLayer/ReputationLabel
@onready var turn_counter_label = $CanvasLayer/TurnCounterLabel

var is_player_turn: bool = true
var actions_this_turn: int = 0
const MAX_ACTIONS_PER_TURN = 2
const MAX_TURNS = 30

# Game resources
var money: int = 50
var co2: int = 0
var iron: int = 50
var reputation: int = 50
var current_turn: int = 1

# Win/loss thresholds
const WIN_MONEY_THRESHOLD = 100
const WIN_REPUTATION_THRESHOLD = 75
const LOSE_CO2_THRESHOLD = 100
const WIN_IRON_THRESHOLD = 25
#event threshold
const LOW_MONEY = 10
const LOW_REPUTATION = 10
const HIGH_CO2 =70
const LOW_IRON = 10
var eventloss = false
var event_loss_description = ""

func _ready():
	reset_turn()
	update_all_labels()

func reset_turn():
	is_player_turn = true
	actions_this_turn = 0
	update_all_labels()
	
func check_end_turn():
	if actions_this_turn >= MAX_ACTIONS_PER_TURN:
		pass # Remove auto end turn

func end_turn():
	if is_player_turn:
		# Process turn effects
		process_card_effects()
		
		# Reset actions
		actions_this_turn = 0
		
		# Increment turn counter only once
		current_turn += 1
		
		# Check win/loss conditions
		check_game_conditions()
		
		# Update UI
		update_all_labels()

func process_card_effects():
	# Process effects from assets field
	for card in assets.cards_holder.get_children():
		if card.is_positive_phase:
			apply_card_effects(card, true)
	
	# Process effects from withdraw field
	for card in withdraw.cards_holder.get_children():
		if not card.is_positive_phase:
			apply_card_effects(card, false)
			
	# Update cards in both fields
	for field in [assets, withdraw]:
		field.end_turn()

func apply_card_effects(card, is_positive: bool):
	var effect = card.poseffect if is_positive else card.negeffect
	# effect format: [description, turns, money, iron, reputation, co2]
	money += effect[2]
	iron += effect[3]
	reputation += effect[4]
	co2 += effect[5]
	if co2 <= 0:
		co2 = 0

func check_game_conditions():
	if current_turn > MAX_TURNS:
		if check_win_condition():
			show_game_over("Victory! You've successfully balanced resources!")
		else:
			show_game_over("Game Over! Failed to achieve balance after 30 turns.")
	elif co2 >= LOSE_CO2_THRESHOLD:
		show_game_over("Game Over! CO2 levels too high!")
	elif eventloss == true:
		show_game_over(event_loss_description)
	elif money <= LOW_MONEY:
		
		pass
	

func check_win_condition() -> bool:
	return (money >= WIN_MONEY_THRESHOLD and 
			reputation >= WIN_REPUTATION_THRESHOLD and 
			co2 < LOSE_CO2_THRESHOLD and 
			iron >= WIN_IRON_THRESHOLD)

func show_game_over(message: String):
	var game_over_dialog = AcceptDialog.new()
	game_over_dialog.dialog_text = message
	add_child(game_over_dialog)
	game_over_dialog.popup_centered()
	game_over_dialog.connect("confirmed", _on_game_over_confirmed)

func _on_game_over_confirmed():
	get_tree().reload_current_scene()

func update_all_labels():
	action_label.text = "Actions remaining: " + str(MAX_ACTIONS_PER_TURN - actions_this_turn)
	money_label.text = "Money: " + str(money)
	co2_label.text = "CO2: " + str(co2)
	iron_label.text = "Iron: " + str(iron)
	reputation_label.text = "Reputation: " + str(reputation)
	turn_counter_label.text = "Turn: " + str(current_turn) + "/" + str(MAX_TURNS)

func track_action():
	if is_player_turn and actions_this_turn < MAX_ACTIONS_PER_TURN:
		actions_this_turn += 1
		update_all_labels()
		check_end_turn()
	else:
		print("No actions remaining this turn!")

func _on_end_turn_pressed() -> void:
	end_turn()

func _on_assets_transfercard(card: Variant) -> void:
	withdraw.set_new_card(card)
#event state goes through the list
func _on_events_eventcard(eventstate: Variant) -> void:
	events.wichevent = eventstate
	events.set_new_card()
