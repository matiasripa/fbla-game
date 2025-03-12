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
@onready var background = $background
@onready var fade_overlay = $fade_overlay
@onready var quit_button = $CanvasLayer/QuitButton
var cardResource = preload("res://example/card/card.tscn")
# Preload the end screen scene
var end_screen_scene = preload("res://end screen.tscn")

#audio streamer
var bg_music := AudioStreamPlayer.new()

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
var actions_this_turn: int = 0
const MAX_ACTIONS_PER_TURN = 2
const MAX_TURNS = 30


# Game resources
var money: int = 50
var co2: int = 0
var iron: int = 100
var reputation: int = 60
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
	Some experts warn that drilling might release harmful gases, but there’s no solid proof yet.
	 Others say it’s just an overreaction.
	Do you start mining? ",
	"ok_messege":"stop the mining",
	"ok_effects": false,#activates effect
	"effect": [+5,10,0,-10],# [money, iron, reputation, co2]
	"no_messege": "yes start",
	"no_effect": true#spawns event card
},
{
	"messege": "Your company’s latest product could revolutionize the market!
	 Testing isn’t fully complete, but no major issues have been found so far.
	 If you launch now, you’ll beat the competition and secure massive profits. 
	Do you go for it?",#bad product
	"ok_messege":"sure go for it ",
	"ok_effects": true,
	"effect": [-10,-6,5,0],# [money, iron, reputation, co2]
	"no_messege": "do not go for it!",
	"no_effect": false
},{
	"messege": " A foreign buyer is offering a fortune for high-quality lumber.
	The forest will take years to recover, but new trees will grow eventually.
	Plus, if you don’t take the deal, someone else will.
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

# Initialize game state
func _ready():
	# Make sure to complete initialization before other nodes try to access this
	process_priority = -1  # Ensure this runs before other nodes

	#the background music
	bg_music.stream = load("res://example/field/Ian Post - Breaking Point.mp3")
	bg_music.autoplay = true
	add_child(bg_music)
	
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
	
	# Connect quit button if not already connected
	if not quit_button.is_connected("pressed", Callable(self, "_on_quit_button_pressed")):
		quit_button.connect("pressed", Callable(self, "_on_quit_button_pressed"))
	
	reset_turn()
	update_all_labels()
	
	# Set initial background
	background.texture = factory_textures[0]

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
		
		# Check if we need to change the factory background
		check_factory_transition()
		
		# Check win/loss conditions
		check_game_conditions()
		
		# Update UI
		update_all_labels()
		if current_turn == 5 || current_turn == 10 || current_turn == 20:
			which_event = randi() % events_types.size()
			event_text(which_event)

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

# Clean up after transition is complete
func _finish_transition():
	is_transitioning = false
	next_factory_texture = null

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

# Check win/loss conditions - UPDATED
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

# Check if win conditions are met - UPDATED
func check_win_condition() -> bool:
	return (money >= WIN_MONEY_THRESHOLD and 
			reputation >= WIN_REPUTATION_THRESHOLD and 
			co2 < LOSE_CO2_THRESHOLD and 
			iron >= WIN_IRON_THRESHOLD)

func show_game_over(message: String):
	# Create an instance of the end screen
	var end_screen = end_screen_scene.instantiate()
	
	# Set the game over reason based on updated conditions
	if co2 >= LOSE_CO2_THRESHOLD:
		end_screen.game_over_reason = "co2"
	elif money < WIN_MONEY_THRESHOLD:
		end_screen.game_over_reason = "money"
	elif reputation < WIN_REPUTATION_THRESHOLD:
		end_screen.game_over_reason = "reputation"
	elif iron < WIN_IRON_THRESHOLD:
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
#IT WORKS SO DONT TOUCH IT (Ahmad: sure i will not <3)
func _on_events_eventcard(eventstate: Variant, event_input: int) -> void:
	if event_input == 1:  # User accepted the event
		# Set the current event type in the events field
		if events_types[which_event]["ok_effects"] == true:
			events.event_setup(which_event)  # Create the event card
		else:#[money, iron, reputation, co2]
			money += events_types[which_event]["effect"][0]
			iron += events_types[which_event]["effect"][1]
			reputation += events_types[which_event]["effect"][2]
			co2 += events_types[which_event]["effect"][3]
			update_all_labels()
	elif event_input == 0:  # User declined the event
		# Handle declined event (maybe apply a different penalty?)
		if events_types[which_event]["no_effect"] == true:
			events.event_setup(which_event) 
		else:#[money, iron, reputation, co2]
			money += events_types[which_event]["effect"][0]
			iron += events_types[which_event]["effect"][1]
			reputation += events_types[which_event]["effect"][2]
			co2 += events_types[which_event]["effect"][3]
			update_all_labels()
		pass
