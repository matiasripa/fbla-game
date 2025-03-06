extends Node

# UI element references
@onready var assets = $CanvasLayer/Assets
@onready var withdraw = $CanvasLayer/Withdraw
@onready var events = $CanvasLayer/Events
@onready var action_label = $CanvasLayer/ActionLabel
@onready var money_label = $CanvasLayer/MoneyLabel
@onready var co2_label = $CanvasLayer/CO2Label
@onready var iron_label = $CanvasLayer/IronLabel
@onready var reputation_label = $CanvasLayer/ReputationLabel
@onready var turn_counter_label = $CanvasLayer/TurnCounterLabel
var cardResource = preload("res://example/card/card.tscn")

# Game state tracking
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

# Event thresholds
const LOW_MONEY = 10
const LOW_REPUTATION = 10
const HIGH_CO2 = 70
const LOW_IRON = 10
#here are the different events,this is for text purposes
var events_types = ["event1","event2","event3"]
var which_event
#-1 for unselected, 0 for no and 1 for yes
var event_text_option_selected = -1 

# Initialize game state
func _ready():
	reset_turn()
	update_all_labels()

# Reset turn state
func reset_turn():
	is_player_turn = true
	actions_this_turn = 0
	update_all_labels()
	
# Check if turn should end automatically
func check_end_turn():
	if actions_this_turn >= MAX_ACTIONS_PER_TURN:
		pass # Remove auto end turn

# Process end of turn
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
		if current_turn == 10:
			which_event = randi() % events_types.size()
			event_text("test",events_types[0])
			

# Process card effects at turn end
func process_card_effects():
	# Process effects from assets field
	for card in assets.cards_holder.get_children():
		if card.is_positive_phase:
			apply_card_effects(card, true, false)
	
	# Process effects from withdraw field
	for card in withdraw.cards_holder.get_children():
		if not card.is_positive_phase:
			apply_card_effects(card, false, false)
	for card in events.cards_holder.get_children():
		apply_card_effects(card, false, true)
	# Update cards in both fields
	for field in [assets, withdraw,events]:
		field.end_turn()

# Apply card effects to game resources
func apply_card_effects(card, is_positive: bool, is_event: bool):
	var effect
	
	if is_event:
		effect = card.eventeffect
	elif is_positive:
		effect = card.poseffect
	else:
		effect = card.negeffect

	# Effect format: [description, turns, money, iron, reputation, co2]
	money += effect[2]
	iron += effect[3]
	reputation += effect[4]
	co2 += effect[5]
	if co2 <= 0:
		co2 = 0


# Check win/loss conditions
func check_game_conditions():
	if current_turn > MAX_TURNS:
		if check_win_condition():
			show_game_over("Victory! You've successfully balanced resources!")
		else:
			show_game_over("Game Over! Failed to achieve balance after 30 turns.")
	elif co2 >= LOSE_CO2_THRESHOLD:
		show_game_over("Game Over! CO2 levels too high!")
#	elif eventloss == true:
#		show_game_over(event_loss_description)
	elif money <= LOW_MONEY:
		pass  # Event handling for low money

# Check if win conditions are met
func check_win_condition() -> bool:
	return (money >= WIN_MONEY_THRESHOLD and 
			reputation >= WIN_REPUTATION_THRESHOLD and 
			co2 < LOSE_CO2_THRESHOLD and 
			iron >= WIN_IRON_THRESHOLD)

# Show game over dialog
func show_game_over(message: String):
	var game_over_dialog = AcceptDialog.new()
	game_over_dialog.dialog_text = message
	add_child(game_over_dialog)
	game_over_dialog.popup_centered()
	game_over_dialog.connect("confirmed", _on_game_over_confirmed)


func event_text(messege: String,event : String):
	var event_dialogue = AcceptDialog.new()
	event_dialogue.dialog_text = messege
	event_dialogue.add_cancel_button("no")
	add_child(event_dialogue)
	event_dialogue.popup_centered()
	event_dialogue.connect("confirmed", on_event_accept)
	event_dialogue.connect("canceled", on_event_decline)
	
	
	
func on_event_accept():
	_on_events_eventcard(which_event,1) 

func on_event_decline():
	_on_events_eventcard(which_event,0)

# Handle game over dialog confirmation
func _on_game_over_confirmed():
	get_tree().reload_current_scene()  # Restart the game

# Update all UI labels with current values
func update_all_labels():
	# Actions label
	action_label.text = "Actions remaining: " + str(MAX_ACTIONS_PER_TURN - actions_this_turn)

	# Money label
	money_label.text = "Money: " + str(money)
	if money >= 50:
		money_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green
	elif money >= 30:
		money_label.add_theme_color_override("font_color", Color(1, 1, 0))  # Yellow
	else:
		money_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red

	# CO2 label (inverted logic since higher CO2 is worse)
	co2_label.text = "CO2: " + str(co2)
	if co2 >= 50:
		co2_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red
	elif co2 >= 30:
		co2_label.add_theme_color_override("font_color", Color(1, 1, 0))  # Yellow
	else:
		co2_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green

	# Iron label
	iron_label.text = "Iron: " + str(iron)
	if iron >= 50:
		iron_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green
	elif iron >= 30:
		iron_label.add_theme_color_override("font_color", Color(1, 1, 0))  # Yellow
	else:
		iron_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red

	# Reputation label
	reputation_label.text = "Reputation: " + str(reputation)
	if reputation >= 50:
		reputation_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green
	elif reputation >= 30:
		reputation_label.add_theme_color_override("font_color", Color(1, 1, 0))  # Yellow
	else:
		reputation_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red

	# Turn counter label stays the same color
	turn_counter_label.text = "Turn: " + str(current_turn) + "/" + str(MAX_TURNS)

# Track action usage
func track_action():
	if is_player_turn and actions_this_turn < MAX_ACTIONS_PER_TURN:
		actions_this_turn += 1
		update_all_labels()
		check_end_turn()
	else:
		print("No actions remaining this turn!")

# End turn button handler
func _on_end_turn_pressed() -> void:
	end_turn()

# Handle card transfer signal from assets
func _on_assets_transfercard(card: Variant) -> void:
	withdraw.set_new_card(card)

# Handle event card signal
func _on_events_eventcard(eventstate: Variant, event_input: int) -> void:
	if event_input == 1:  # User accepted the event
		# Set the current event type in the events field
		events.wichevent = which_event  
		events.event_setup()  # Create the event card
	elif event_input == 0:  # User declined the event
		# Handle declined event (maybe apply a different penalty?)
		pass


	
