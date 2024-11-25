class_name Card  
extends Control  

# Declare onready variables for UI elements and components
@onready var color_rect: ColorRect = $ColorRect  #  Reference to the ColorRect node for visual representation
@onready var label: Label = $Label  #  Reference to the Label node for displaying text
@onready var name_label: Label = $NameLabel  #  Corrected from %NameLabel to $NameLabel for proper reference
@onready var state_machine: CardStateMachine = $CardStateMachine  #  Reference to the state machine for handling card states
@onready var drop_point_detector: Area2D = $DropPointDetector  #  Reference to the Area2D node for detecting drop points
@onready var card_detector: Area2D = $CardsDetector  #  Reference to the Area2D node for detecting other cards
@onready var home_field: Node  #  Declare as Node; can be further specified if needed
@onready var clickable = true  #  Boolean to indicate if the card can be clicked

# Variables for card properties
var index: int = 0  #  Index for identifying the card within a collection
var poseffect = []  #  Array to store positive effects related to the card
var negeffect = []  #  Array to store negative effects related to the card

func _ready():
	name_label.text = name  # Set the name label text to the card's name
	
	# Debugging: Print the parent and its children to verify the hierarchy
	print("Parent Node:", get_parent().name)  #  Output the name of the parent node for debugging
	print("Children of Parent:", get_parent().get_children())  #  Output the children of the parent node for debugging
	
	# Attempt to find the CardsHolder node
	home_field = get_parent()  # Ahmad: Assign the parent node (CardsHolder) to home_field

	# Check if home_field was set correctly
	if home_field == null:
		print("Error: CardsHolder node not found.")  #  Print an error message if home_field is null
	else:
		print("Successfully found CardsHolder:", home_field)  # Confirm successful assignment of home_field

func _input(event):
	state_machine.on_input(event)  # Pass input events to the state machine for processing

func _on_gui_input(event):
	state_machine.on_gui_input(event)  # Pass GUI input events to the state machine for processing

func _on_mouse_entered():
	# Handle mouse enter events
	if !home_field.isasset && !home_field.iswithdraw:  # Ahmad: Check if home_field is not an asset or withdrawal
		state_machine.on_mouse_entered()  #  Call the on_mouse_entered function in the state machine
	elif home_field.isasset:
		pass  #  Do nothing if the home_field is an asset
	elif home_field.iswithdraw:
		pass  #  Do nothing if the home_field is a withdrawal

func _on_mouse_exited():
	state_machine.on_mouse_exited()  # Call the on_mouse_exited function in the state machine
