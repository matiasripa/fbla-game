extends Node

# UI element references
@onready var multiplay = true
@onready var assets = $CanvasLayer/Assets
@onready var withdraw = $CanvasLayer/Withdraw
@onready var events = $CanvasLayer/Events
@onready var p2_events_field = $CanvasLayer/P2EventsField  # New field for Player 2
@onready var action_label = $CanvasLayer/ActionLabel
@onready var money_label = $CanvasLayer/MoneyLabel
@onready var co2_label = $CanvasLayer/CO2Label
@onready var iron_label = $CanvasLayer/IronLabel
@onready var reputation_label = $CanvasLayer/ReputationLabel
@onready var turn_counter_label = $CanvasLayer/TurnCounterLabel
@onready var player_turn_label = $CanvasLayer/PlayerTurnLabel  # New label to show active player
@onready var p2_action_label = $CanvasLayer/P2ActionLabel  # Action label for Player 2
@onready var background = $background
@onready var fade_overlay = $fade_overlay
@onready var quit_button = $CanvasLayer/QuitButton
var cardResource = preload("res://example/card/card.tscn")

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
var is_player1_active: bool = true  # Track which player is active
var actions_this_turn: int = 0
var p2_actions_this_turn: int = 0  # Track Player 2's actions
const MAX_ACTIONS_PER_TURN = 2
const P2_MAX_ACTIONS_PER_TURN = 1  # Player 2 gets 1 action per turn
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
const LOSE_CO2_THRESHOLD = 60
const WIN_IRON_THRESHOLD = 10

# Event thresholds
const LOW_MONEY = 10
const LOW_REPUTATION = 10
const HIGH_CO2 = 70
const LOW_IRON = 10

# Custom event cards for Player 2
var p2_event_cards = [
	{
		"name": "Environmental Protest",
		"description": "Protestors block your factory gates!",
		"effect": [-5, 0, -8, 0]  # [money, iron, reputation, co2]
	},
	{
		"name": "Factory Leak",
		"description": "A chemical leak has been detected!",
		"effect": [-10, -5, -5, 8]
	},
	{
		"name": "Tax Audit",
		"description": "Government auditors found discrepancies!",
		"effect": [-15, 0, -3, 0]
	},
	{
		"name": "Market Crash",
		"description": "Iron prices plummet overnight!",
		"effect": [-5, -20, 0, 0]
	},
	{
		"name": "Breakthrough",
		"description": "Your R&D team discovered a pollution-causing material!",
		"effect": [10, 10, 0, 12]
	}
]

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

# Initialize game state
func _ready():
	# Make sure to complete initialization before other nodes try to access this
	process_priority = -1  # Ensure this runs before other nodes
	
	# Create the Player 2 events field if it doesn't exist
	if not $CanvasLayer.has_node("P2EventsField"):
		var p2_field = load("res://example/field/field.tscn").instantiate()
		p2_field.name = "P2EventsField"
		p2_field.position = Vector2(589, 50)  # Position above the regular events field
		p2_field.get_node("Label").text = "Player 2 Events"
		p2_events_field = p2_field
	
	# Create Player Turn Label if it doesn't exist
	if not $CanvasLayer.has_node("PlayerTurnLabel"):
		var label = Label.new()
		label.name = "PlayerTurnLabel"
		label.text = "Current Player: Player 1"
		label.position = Vector2(20, 20)
		$CanvasLayer.add_child(label)
		player_turn_label = label
	
	# Create Player 2 Action Label if it doesn't exist
	if not $CanvasLayer.has_node("P2ActionLabel"):
		var label = Label.new()
		label.name = "P2ActionLabel"
		label.text = "P2 Actions: 1/1"
		label.position = Vector2(653, 491)  # Below the regular action label
		$CanvasLayer.add_child(label)
		p2_action_label = label
	
	# Create Player 2 Turn Button if it doesn't exist
	if not $CanvasLayer.has_node("P2EndTurn"):
		var button = Button.new()
		button.name = "P2EndTurn"
		button.text = "End P2 Turn"
		button.position = Vector2(450, 595)
		button.connect("pressed", Callable(self, "_on_p2_end_turn_pressed"))
		$CanvasLayer.add_child(button)
	
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
	
	# Create Draw P2 Event Card button
	if not $CanvasLayer.has_node("DrawP2EventCard"):
		var button = Button.new()
		button.name = "DrawP2EventCard"
		button.text = "Create Event"
		button.position = Vector2(450, 565)
		button.connect("pressed", Callable(self, "_on_draw_p2_event_card_pressed"))
		$CanvasLayer.add_child(button)
	
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
	is_player1_active = true
	actions_this_turn = 0
	p2_actions_this_turn = 0
	update_all_labels()
	
# Player 2 turn handling
func start_player2_turn():
	is_player1_active = false
	p2_actions_this_turn = 0
	player_turn_label.text = "Current Player: Player 2"
	update_all_labels()

# Player 2 end turn button handler
func _on_p2_end_turn_pressed():
	if !is_player1_active:
		process_p2_events()
		is_player1_active = true
		player_turn_label.text = "Current Player: Player 1"
		update_all_labels()

# Process Player 2's event cards
func process_p2_events():
	# Process all event cards in Player 2's field
	for card in p2_events_field.cards_holder.get_children():
		if card.has_method("get_event_effect"):
			var effect = card.get_event_effect()
			apply_p2_event_effect(effect)

# Apply effects from Player 2's event card
func apply_p2_event_effect(effect):
	# Effect format: [money, iron, reputation, co2]
	money += effect[0]
	iron += effect[1]
	reputation += effect[2]
	co2 += effect[3]
	
	# Prevent negative values
	if co2 < 0:
		co2 = 0
	if money < 0:
		money = 0
	if iron < 0:
		iron = 0
	if reputation < 0:
		reputation = 0

# Draw a Player 2 event card
func _on_draw_p2_event_card_pressed():
	if !is_player1_active and p2_actions_this_turn < P2_MAX_ACTIONS_PER_TURN:
		var event_count = p2_events_field.cards_holder.get_child_count()
		
		if event_count < 3:  # Limit to 3 event cards at a time
			# Create a new card
			create_p2_event_card()
			p2_actions_this_turn += 1
			update_all_labels()
		else:
			print("Maximum event cards reached!")
	else:
		print("Not Player 2's turn or no actions remaining!")

# Create a new event card for Player 2
func create_p2_event_card():
	# Choose a random event card type
	var event_index = randi() % p2_event_cards.size()
	var event = p2_event_cards[event_index]
	
	# Create the card instance (using the regular card scene for now)
	var card = cardResource.instantiate()
	card.card_name = event["name"]
	card.description = event["description"]
	
	# Store the event effect data in the card
	card.eventeffect = ["P2 Event", 1] + event["effect"]  # [description, turns, money, iron, reputation, co2]
	
	# Add the card to Player 2's field
	p2_events_field.cards_holder.add_child(card)
	
	print("Player 2 created event: " + event["name"])

# Check if turn should end automatically
func check_end_turn():
	if actions_this_turn >= MAX_ACTIONS_PER_TURN:
		pass # Remove auto end turn

# Process end of turn
func end_turn():
	if is_player_turn and is_player1_active:
		# Process turn effects
		process_card_effects()
		
		# Reset actions
		actions_this_turn = 0
		
		# Start Player 2's turn
		start_player2_turn()
		
		# Update UI
		update_all_labels()
		
		
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
