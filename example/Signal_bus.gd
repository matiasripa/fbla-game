extends Node


# UI element references
@onready var multiplay = false  # Changed to false by default
@onready var assets = $CanvasLayer/Assets
@onready var withdraw = $CanvasLayer/Withdraw
@onready var events = $CanvasLayer/Events
@onready var action_label = $CanvasLayer/ActionLabel
@onready var money_label = $CanvasLayer/MoneyLabel
@onready var co2_label = $CanvasLayer/CO2Label
@onready var iron_label = $CanvasLayer/IronLabel
@onready var reputation_label = $CanvasLayer/ReputationLabel
@onready var turn_counter_label = $CanvasLayer/TurnCounterLabel
@onready var background = $background
@onready var fade_overlay = $fade_overlay
@onready var quit_button = $CanvasLayer/QuitButton
@onready var current_player_label = $CanvasLayer/CurrentPlayerLabel
@onready var draw_cards_button = $CanvasLayer/DrawCards
var cardResource = preload("res://example/card/card.tscn")
# Preload the end screen scene
var end_screen_scene = preload("res://end screen.tscn")

# Background images - 15 factory images
var factory_textures = [
	preload("res://factory/fact1.png"),
	preload("res://factory/fact2.png"),
	preload("res://factory/fact3.png"),
	preload("res://factory/fact4.png"),
	preload("res://factory/fact5.png"),
	preload("res://factory/fact6.png"),
	preload("res://factory/fact7.png"),
	preload("res://factory/fact8.png"),
	preload("res://factory/fact9.png"),
	preload("res://factory/fact10.png"),
	preload("res://factory/fact11.png"),
	preload("res://factory/fact12.png"),
	preload("res://factory/fact13.png"),
	preload("res://factory/fact14.png"),
	preload("res://factory/fact15.png")
]
var current_factory_index = 0

# Fade transition variables
var transition_tween: Tween
var next_factory_texture = null
var is_transitioning = false

# Game state tracking
var is_player_turn: bool = true
var current_player: int = 1  # Player 1 (factory owner) or Player 2 (event controller)
var actions_this_turn: int = 0
var player2_actions_this_turn: int = 0  # Track Player 2's actions separately
const MAX_ACTIONS_PER_TURN = 2
const MAX_PLAYER2_ACTIONS_PER_TURN = 1  # Player 2 gets 1 event card per turn
const MAX_TURNS = 30


# Game resources
var current_turn: int = 1

# Win/loss thresholds - UPDATED
const WIN_MONEY_THRESHOLD = 50
const WIN_REPUTATION_THRESHOLD = 50
const LOSE_CO2_THRESHOLD = 60  # Changed from 51 to 60
const WIN_IRON_THRESHOLD = 10  # Changed from 300 to 10

# Event thresholds
const LOW_MONEY = 10
const LOW_REPUTATION = 10
const HIGH_CO2 = 70
const LOW_IRON = 10
#here are the different events
#if it gives false,it gives you resources inmedietly,if true it gives an event card
var events_types = [{
	#this is for acid rain
	"messege": " A massive underground mineral deposit could skyrocket your profits. 
	Some experts warn that drilling might release harmful gases, but there's no solid proof yet.
	 Others say it's just an overreaction.
	Do you start mining? ",
	"ok_messege":"stop the mining",
	"ok_effects": false,#activates effect
	"effect": [+5,10,0,-10],# [money, iron, reputation, co2]
	"no_messege": "yes start",
	"no_effect": true#spawns event card
},
{
	"messege": "Your company's latest product could revolutionize the market!
	 Testing isn't fully complete, but no major issues have been found so far.
	 If you launch now, you'll beat the competition and secure massive profits. 
	Do you go for it?",#bad product
	"ok_messege":"sure go for it ",
	"ok_effects": true,
	"effect": [-10,-6,5,0],# [money, iron, reputation, co2]
	"no_messege": "do not go for it!",
	"no_effect": false
},{
	"messege": " A foreign buyer is offering a fortune for high-quality lumber.
	The forest will take years to recover, but new trees will grow eventually.
	Plus, if you don't take the deal, someone else will.
	Do you go ahead with large-scale logging?",#deforestation
	"ok_messege":"do not take it",
	"ok_effects": false,
	"effect": [-5,-2,5,0],# [money, iron, reputation, co2]
	"no_messege": "take it ",
	"no_effect": true
}
]
var which_event
#-1 for unselected, 0 for no and 1 for yes
var event_text_option_selected = -1 
var available_event_indices = []  # Store indices of events player 2 can choose from



# Updated _on_assets_transfercard function
func _on_assets_transfercard(card: Variant) -> void:
	# Check if the destination field is the event field in multiplayer mode
	var destination_field = card.get_parent()
	if destination_field == event_field and multiplay:
		# Don't destroy the card, just accept it in the event field
		if card.has_meta("is_event_card") or card.get("is_event_card") == true:
			event_field.accept_card(card)
		else:
			withdraw.set_new_card(card)
	else:
		# Original behavior - cards go to withdraw field
		withdraw.set_new_card(card)

# Add this function to make the event field properly handle cards
func _on_event_field_transfercard(card: Variant) -> void:
	# Handle cards entering the event field
	if card.has_meta("is_event_card") or card.get("is_event_card") == true:
		event_field.accept_card(card)
	else:
		# Non-event cards should go to withdraw
		withdraw.set_new_card(card)




# Update present_event_choice function in Signal_bus.gd
func present_event_choice(event_index):
	# Create a dialog for player 2 to choose what to do with the event
	var choice_dialog = ConfirmationDialog.new()
	choice_dialog.title = "Event Card Choice"
	choice_dialog.dialog_text = "Event card drawn: " + events_types[event_index]["messege"]
	choice_dialog.get_ok_button().text = events_types[event_index]["ok_messege"]
	choice_dialog.get_cancel_button().text = events_types[event_index]["no_messege"]

	# Connect signals for player choice
	choice_dialog.confirmed.connect(Callable(self, "_on_event_accept").bind(event_index))
	choice_dialog.canceled.connect(Callable(self, "_on_event_decline").bind(event_index))

	# Show dialog
	add_child(choice_dialog)
	choice_dialog.popup_centered()

	# Clean up when closed
	choice_dialog.close_requested.connect(choice_dialog.queue_free)





@onready var event_field = $CanvasLayer/EventField



# Modify the draw_event_card function to draw two random event cards and disable the button afterwards
func draw_event_card():
	if player2_actions_this_turn < MAX_PLAYER2_ACTIONS_PER_TURN:
		# Check if we have available events
		if available_event_indices.size() > 0:
			# Determine how many cards to draw (up to 2 cards)
			var cards_to_draw = min(2, available_event_indices.size())
			
			for i in range(cards_to_draw):
				# Randomly select an event index
				var index = randi() % available_event_indices.size()
				var which_event = available_event_indices[index]
				
				# Remove this event from available options
				available_event_indices.remove_at(index)
				
				# Create the event card in the event field
				var card = event_field.event_setup(which_event)
				
				# Make sure the card is tagged as an event card
				if card:
					card.is_event_card = true
					print("Event card " + str(i+1) + " created and tagged")
			
			# Update actions - counts as one action
			player2_actions_this_turn += 1
			update_all_labels()
			
			# Disable the draw button after Player 2 uses their action
			if current_player == 2:
				draw_cards_button.disabled = true
				print("Draw button disabled for Player 2")
		else:
			# Refresh events if we've used them all
			_replenish_events()
			draw_event_card()
	else:
		print("No actions remaining for Player 2 this turn!")


# Also update _confirm_multiplayer and _confirm_singleplayer to ensure button state is correct on game start
func _confirm_multiplayer():
	multiplay = true
	current_player_label.text = "Current Player: 1 (Factory Owner)"
	current_player_label.show()
	
	# Hide destroy field in multiplayer
	$CanvasLayer/destroy.hide()
	$CanvasLayer/destroy.visible = false
	
	# Hide Events field in multiplayer (regular events field)
	$CanvasLayer/Events.hide()
	$CanvasLayer/Events.visible = false
	
	# Show event field in multiplayer (for Player 2's event cards)
	$CanvasLayer/EventField.show()
	$CanvasLayer/EventField.visible = true
	
	reset_turn()
	update_all_labels()
	update_draw_button_text()
	draw_cards_button.disabled = false  # Ensure button is enabled at start
	
	# Set initial background
	background.texture = factory_textures[0]
	print("Multiplayer mode selected")

func _confirm_singleplayer():
	multiplay = false
	current_player_label.hide()
	
	# Show destroy field in singleplayer
	$CanvasLayer/destroy.show()
	$CanvasLayer/destroy.visible = true
	
	# Show Events field in singleplayer
	$CanvasLayer/Events.show()
	$CanvasLayer/Events.visible = true
	
	# Hide event field in singleplayer (Player 2's event field)
	$CanvasLayer/EventField.hide()
	$CanvasLayer/EventField.visible = false
	
	reset_turn()
	update_all_labels()
	draw_cards_button.disabled = false  # Ensure button is enabled at start
	
	# Set initial background
	background.texture = factory_textures[0]
	print("Singleplayer mode selected")

# In _on_draw_cards_pressed, make sure we handle the button disabling logic
func _on_draw_cards_pressed():
	if !multiplay:
		# In singleplayer, always use player 1's action
		$CanvasLayer/hand._on_button_pressed()
	else:
		# In multiplayer, route based on current player
		if current_player == 1:
			$CanvasLayer/hand._on_button_pressed()
		else:
			# Player 2 draws event cards
			draw_event_card()
			# Note: We don't need to disable the button here as it's handled in draw_event_card
	
	update_draw_button_text()
# Update the button text to reflect the functionality
func update_draw_button_text():
	if multiplay:
		if current_player == 1:
			draw_cards_button.text = "Draw Card"
		else:
			draw_cards_button.text = "Draw Event"
	else:
		draw_cards_button.text = "Draw Card"

# Make sure MAX_PLAYER2_ACTIONS_PER_TURN is set to 1 in the constants section
# const MAX_PLAYER2_ACTIONS_PER_TURN = 1  # Player 2 gets 1 action per turn






func can_interact_with_card(card, target_field = null):
	if !multiplay:
		# In singleplayer, all cards can be interacted with
		return true
	
	# Check if the card has the is_event_card property
	var is_event = false
	if card.has_method("get_meta") and card.has_meta("is_event_card"):
		is_event = card.get_meta("is_event_card")
	elif card.get("is_event_card") != null:
		is_event = card.is_event_card
	
	# In multiplayer, restrict based on player and card type
	if current_player == 1 and is_event:
		# Player 1 cannot interact with event cards
		print("Player 1 cannot interact with event cards!")
		return false
	elif current_player == 2 and !is_event:
		# Player 2 cannot interact with regular cards
		print("Player 2 cannot interact with regular cards!")
		return false
	
	# Field-specific restrictions for Player 2
	if current_player == 2 and is_event and target_field != null:
		# Player 2 can play event cards in both Events field and event_field
		if target_field != events and target_field != event_field:
			print("Player 2 can only play event cards in designated event fields!")
			return false
	
	return true




func _on_drop_in_field(field):
	var signalbus = get_node("/root/Game/Signalbus")
	
	if signalbus.can_interact_with_card(self, field):
		# Process dropping the card in this field
		field.accept_card(self)


func end_turn():
	if multiplay:
		# In multiplayer, switch between player 1 and 2
		if current_player == 1:
			# If player 1 ends turn, switch to player 2
			current_player = 2
			current_player_label.text = "Current Player: 2 (Event Controller)"
			actions_this_turn = 0
			player2_actions_this_turn = 0  # Reset player 2's actions
			is_player_turn = true
			
			update_draw_button_text()
			update_all_labels()  # Update labels to reflect the player change
		else:
			# Player 2 ended turn, switch back to player 1
			current_player = 1
			current_player_label.text = "Current Player: 1 (Factory Owner)"
			player2_actions_this_turn = 0
			actions_this_turn = 0  # Reset player 1's actions
			is_player_turn = true
			
			update_draw_button_text()
			update_all_labels()  # Update labels to reflect the player change
			advance_turn()
	else:
		# Singleplayer logic
		advance_turn()
		
		# Check if we need to show an event
		if current_turn == 5 || current_turn == 10 || current_turn == 20:
			which_event = randi() % events_types.size()
			event_text(which_event)

# Function to highlight the Events field when it's Player 2's turn

# Initialize game state
func _ready():
	# Make sure to complete initialization before other nodes try to access this
	process_priority = -1  # Ensure this runs before other nodes
	
	# Connect event_field transfercard signal if it exists and isn't already connected
	if event_field and event_field.has_signal("transfercard") and not event_field.is_connected("transfercard", Callable(self, "_on_event_field_transfercard")):
		event_field.connect("transfercard", Callable(self, "_on_event_field_transfercard"))
	
	# Rest of your existing _ready function...
	# Connect draw button signals
	if draw_cards_button.is_connected("pressed", Callable($CanvasLayer/hand, "_on_button_pressed")):
		draw_cards_button.disconnect("pressed", Callable($CanvasLayer/hand, "_on_button_pressed"))

	if not draw_cards_button.is_connected("pressed", Callable(self, "_on_draw_cards_pressed")):
		draw_cards_button.connect("pressed", Callable(self, "_on_draw_cards_pressed"))

	
	# Create the fade overlay if it doesn't exist
	if not has_node("fade_overlay"):
		var overlay = ColorRect.new()
		overlay.name = "fade_overlay"
		overlay.color = Color(0, 0, 0, 0)  # Start fully transparent
		overlay.size = Vector2(1200, 700)  # Make sure it covers the whole screen
		overlay.z_index = 100  # Ensure it's drawn on top
		add_child(overlay)
		fade_overlay = overlay
	
	# Create quit button if it doesn't exist
	if not $CanvasLayer.has_node("QuitButton"):
		var button = Button.new()
		button.name = "QuitButton"
		button.text = "Quit"
		button.position = Vector2(20, 650)  # Bottom left corner
		button.size = Vector2(80, 30)
		$CanvasLayer.add_child(button)
		quit_button = button
	
	# Create current player label if doesn't exist
	if not $CanvasLayer.has_node("CurrentPlayerLabel"):
		var label = Label.new()
		label.name = "CurrentPlayerLabel"
		label.text = "Current Player: 1 (Factory Owner)"
		label.position = Vector2(500, 10)  # Top center
		$CanvasLayer.add_child(label)
		current_player_label = label
	
	# Connect quit button if not already connected
	if not quit_button.is_connected("pressed", Callable(self, "_on_quit_button_pressed")):
		quit_button.connect("pressed", Callable(self, "_on_quit_button_pressed"))
	
	# Initialize available events for player 2
	for i in range(events_types.size()):
		available_event_indices.append(i)
	
	# Connect draw button signals
	if not draw_cards_button.is_connected("pressed", Callable(self, "_on_draw_cards_pressed")):
		draw_cards_button.connect("pressed", Callable(self, "_on_draw_cards_pressed"))
	
	# Show multiplayer selection dialog
	show_multiplayer_dialog()

# Show dialog to choose multiplayer or singleplayer
func show_multiplayer_dialog():
	var mode_dialog = ConfirmationDialog.new()
	mode_dialog.title = "Game Mode"
	mode_dialog.dialog_text = "Would you like to play in multiplayer mode?"
	mode_dialog.get_ok_button().text = "Yes (Multiplayer)"
	mode_dialog.get_cancel_button().text = "No (Singleplayer)"
	
	# Connect the signal before adding to scene tree
	mode_dialog.confirmed.connect(_confirm_multiplayer)
	mode_dialog.canceled.connect(_confirm_singleplayer)
	
	# Add dialog to scene
	add_child(mode_dialog)
	mode_dialog.popup_centered()
	
	# Ensure dialog is freed when closed
	mode_dialog.close_requested.connect(mode_dialog.queue_free)



# Process input events for ESC key handling
func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_on_quit_button_pressed()

# Quit button pressed handler - FIXED
func _on_quit_button_pressed():
	var quit_dialog = ConfirmationDialog.new()
	quit_dialog.title = "Quit Game"
	quit_dialog.dialog_text = "Are you sure you want to quit the game?"
	quit_dialog.get_ok_button().text = "Yes"
	quit_dialog.get_cancel_button().text = "No"
	
	# Connect the signal before adding to scene tree
	quit_dialog.confirmed.connect(_confirm_quit)
	
	# Add dialog to scene
	add_child(quit_dialog)
	quit_dialog.popup_centered()
	
	# Ensure dialog is freed when closed
	quit_dialog.close_requested.connect(quit_dialog.queue_free)
	quit_dialog.canceled.connect(quit_dialog.queue_free)

# Confirm quit handler
func _confirm_quit():
	print("Quitting game...")
	get_tree().quit()

# Reset turn state
func reset_turn():
	if multiplay:
		current_player = 1  # Start with player 1

	
	is_player_turn = true
	actions_this_turn = 0
	player2_actions_this_turn = 0
	update_all_labels()
	update_draw_button_text()
	
# Check if turn should end automatically
func check_end_turn():
	if actions_this_turn >= MAX_ACTIONS_PER_TURN and current_player == 1:
		pass # Remove auto end turn
	elif player2_actions_this_turn >= MAX_PLAYER2_ACTIONS_PER_TURN and current_player == 2:
		pass # Remove auto end turn



# Update event response handlers in Signal_bus.gd
func _on_event_accept(event_index):
	if events_types[event_index]["ok_effects"] == true:
		# Create event card in the event field
		event_field.event_setup(event_index)
	else:
		# Apply immediate effects [money, iron, reputation, co2]
		Global.money += events_types[event_index]["effect"][0]
		Global.iron += events_types[event_index]["effect"][1]
		Global.reputation += events_types[event_index]["effect"][2]
		Global.co2 += events_types[event_index]["effect"][3]
		update_all_labels()

func _on_event_decline(event_index):
	if events_types[event_index]["no_effect"] == true:
		# Create event card in the event field
		event_field.event_setup(event_index)
	else:
		# Apply immediate effects [money, iron, reputation, co2]
		Global.money += events_types[event_index]["effect"][0]
		Global.iron += events_types[event_index]["effect"][1]
		Global.reputation += events_types[event_index]["effect"][2]
		Global.co2 += events_types[event_index]["effect"][3]
		update_all_labels()





# Replenish available events - NEW FUNCTION
func _replenish_events():
	available_event_indices.clear()
	for i in range(events_types.size()):
		available_event_indices.append(i)
	print("Events replenished for Player 2")

# Track action usage for Player 2 - NEW FUNCTION
func track_player2_action():
	if is_player_turn and player2_actions_this_turn < MAX_PLAYER2_ACTIONS_PER_TURN:
		player2_actions_this_turn += 1
		update_all_labels()
		check_end_turn()
	else:
		print("No actions remaining for Player 2 this turn!")




# Advance to next turn and process effects
func advance_turn():
	# Process turn effects
	process_card_effects()
	
	# Reset actions
	actions_this_turn = 0
	
	# Increment turn counter only once
	current_turn += 1
	
	# Check if we need to change the factory background
	check_factory_transition()
	
	# Check win/loss conditions
	check_game_conditions()
	
	# Update UI
	update_all_labels()
	update_draw_button_text()




func _finish_transition():
	is_transitioning = false
	next_factory_texture = null



# Check if we need to transition to a new factory background
func check_factory_transition():
	# Every 2 turns, change to the next factory image
	if current_turn % 2 == 1 and current_turn > 1:
		var next_factory_index = (current_turn - 1) / 2
		if next_factory_index < factory_textures.size():
			transition_to_factory(next_factory_index)

# Transition to a new factory background with fade effect
func transition_to_factory(factory_index: int):
	# Check if the factory index is valid
	if factory_index < 0 or factory_index >= factory_textures.size():
		return
	
	# If already transitioning, cancel the previous tween
	if is_transitioning and transition_tween:
		transition_tween.kill()
	
	is_transitioning = true
	next_factory_texture = factory_textures[factory_index]
	
	# Create a new tween for the fade out
	transition_tween = create_tween()
	transition_tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 0.5)  # Fade to black
	transition_tween.tween_callback(Callable(self, "_change_background").bind(factory_index))
	transition_tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 0), 0.5)  # Fade back in
	transition_tween.tween_callback(Callable(self, "_finish_transition"))

# Change the background texture (called mid-transition)
func _change_background(factory_index: int):
	background.texture = factory_textures[factory_index]
	current_factory_index = factory_index
	print("Factory updated to: ", factory_index + 1)


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
	Global.money += effect[2]
	Global.iron += effect[3]
	Global.reputation += effect[4]
	Global.co2 += effect[5]
	if Global.co2 <= 0:
		Global.co2 = 0

# Check win/loss conditions - UPDATED
func check_game_conditions():
	if current_turn > MAX_TURNS:
		if check_win_condition():
			show_game_over("Victory! You've successfully balanced resources!")
		else:
			show_game_over("Game Over! Failed to achieve balance after 30 turns.")
	elif Global.co2 >= LOSE_CO2_THRESHOLD:
		show_game_over("Game Over! CO2 levels too high!")
#	elif eventloss == true:
#		show_game_over(event_loss_description)
	elif Global.money <= LOW_MONEY:
		pass  # Event handling for low money

# Check if win conditions are met - UPDATED
func check_win_condition() -> bool:
	return (Global.money >= WIN_MONEY_THRESHOLD and 
			Global.reputation >= WIN_REPUTATION_THRESHOLD and 
			Global.co2 < LOSE_CO2_THRESHOLD and 
			Global.iron >= WIN_IRON_THRESHOLD)

func show_game_over(message: String):
	# Create an instance of the end screen
	var end_screen = end_screen_scene.instantiate()
	
	# Set the game over reason based on updated conditions
	if Global.co2 >= LOSE_CO2_THRESHOLD:
		end_screen.game_over_reason = "co2"
	elif Global.money < WIN_MONEY_THRESHOLD:
		end_screen.game_over_reason = "money"
	elif Global.reputation < WIN_REPUTATION_THRESHOLD:
		end_screen.game_over_reason = "reputation"
	elif Global.iron < WIN_IRON_THRESHOLD:
		end_screen.game_over_reason = "money"  # Using money background for iron shortage
	elif check_win_condition():
		end_screen.game_over_reason = "victory"
	else:
		# Default game over (e.g., ran out of turns without winning)
		end_screen.game_over_reason = "money"
	
	# Set the message (even though we're not displaying it)
	end_screen.game_over_message = message
	
	# Add it to the scene tree
	get_tree().root.add_child(end_screen)
	
	# Remove the current scene
	queue_free()
func event_text(event : int):
	var event_dialogue = AcceptDialog.new()
	event_dialogue.dialog_text = events_types[event]["messege"]
	event_dialogue.ok_button_text = events_types[event]["ok_messege"]
	event_dialogue.add_cancel_button(events_types[event]["no_messege"])
	add_child(event_dialogue)
	event_dialogue.popup_centered()
	event_dialogue.connect("confirmed", on_event_accept)
	event_dialogue.connect("canceled", on_event_decline)
	
func on_event_accept():
	_on_events_eventcard(which_event,1) 

func on_event_decline():
	_on_events_eventcard(which_event,0)

# Update all UI labels with current values
# Update all UI labels with current values
func update_all_labels():
	# Actions label - Updated for player 2 in multiplayer
	if multiplay and current_player == 2:
		action_label.text = "Actions remaining: " + str(MAX_PLAYER2_ACTIONS_PER_TURN - player2_actions_this_turn)
	else:
		action_label.text = "Actions remaining: " + str(MAX_ACTIONS_PER_TURN - actions_this_turn)
	
	Global.emit_signal("changeLabels")

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




# Handle event card signal
#IT WORKS SO DONT TOUCH IT (Ahmad: sure i will not <3)
# Handle event card signal
func _on_events_eventcard(event_index: Variant, event_input: int) -> void:
	if multiplay:
		# In multiplayer, event cards should go to the event field
		event_field.event_setup(event_index)
	else:
		# Original singleplayer logic
		if event_input == 1:  # User accepted the event
			if events_types[event_index]["ok_effects"] == true:
				events.event_setup(event_index)  # Create the event card
			else:
				Global.money += events_types[event_index]["effect"][0]
				Global.iron += events_types[event_index]["effect"][1]
				Global.reputation += events_types[event_index]["effect"][2]
				Global.co2 += events_types[event_index]["effect"][3]
				update_all_labels()
		elif event_input == 0:  # User declined the event
			if events_types[event_index]["no_effect"] == true:
				events.event_setup(event_index)
			else:
				Global.money += events_types[event_index]["effect"][0]
				Global.iron += events_types[event_index]["effect"][1]
				Global.reputation += events_types[event_index]["effect"][2]
				Global.co2 += events_types[event_index]["effect"][3]
				update_all_labels()
