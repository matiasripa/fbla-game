class_name Card  
extends Control  

# Declare onready variables for UI elements and components
@onready var label: Label = $Label  # Reference to the Label node for displaying text
@onready var name_label: Label = $NameLabel  # Corrected from %NameLabel to $NameLabel for proper reference
@onready var turn_label: Label = $turn_label  # Shows turns
@onready var state_machine: CardStateMachine = $CardStateMachine  # Reference to the state machine for handling card states
@onready var drop_point_detector: Area2D = $DropPointDetector  # Reference to the Area2D node for detecting drop points
@onready var card_detector: Area2D = $CardsDetector  # Reference to the Area2D node for detecting other cards
@onready var home_field: Node  # Declare as Node; can be further specified if needed
@onready var clickable = true  # Boolean to indicate if the card can be clicked
@onready var shadow_texture_rect: TextureRect =  $ColorRect/TextureRect # Reference to the TextureRect for shadow
var tween_rot: Tween
var tween_hover: Tween
var tween_destroy: Tween
var tween_handle: Tween
var right_click_active: bool = false

@onready var card_texture: TextureRect = $ColorRect
@onready var collision_shape = $destroy/CollisionShape2D
# Variables for card properties
var index: int = 0  # Index for identifying the card within a collection
var card_positive = [
	["good status1", 1, 2, 3, 4, 5],
	["good status2", 1, 3, 3, 4, 5],
	["good status3", 1, 5, 3, 4, 5]
]
var card_negative = [
	["bad status1", 1, 2, 3, 4, 5],
	["bad status2", 1, 3, 3, 4, 5],
	["bad status3", 1, 4, 3, 4, 5]
]
# Card values: [description of the card, amount of turns, money, iron, reputation, CO2]
var poseffect = ["good status1", 1, 2, 3, 4, 5]  # Array to store positive effects related to the card
var negeffect = ["bad status1", 1, 2, 3, 4, 5]  # Array to store negative effects related to the card
var turn = -1

func _ready():
	poseffect = card_positive[randi() % card_positive.size()]
	negeffect = card_negative[randi() % card_negative.size()]
	turn = poseffect[2]
	name_label.text = name  # Set the name label text to the card's name
	turn_label.text = str(turn) + " turn"
	
	# Initially hide the shadow texture
	shadow_texture_rect.visible = false

	# Add input handling for right click
	gui_input.connect(_on_card_gui_input)

	# Attempt to find the CardsHolder node
	home_field = get_parent()  # Ahmad: Assign the parent node (CardsHolder) to home_field

	# Check if home_field was set correctly
	if home_field == null:
		print("Error: CardsHolder node not found.")  # Print an error message if home_field is null
	else:
		print("Successfully found CardsHolder:", home_field)

func _on_card_gui_input(event: InputEvent):
	if event.is_action_pressed("mouse_right") and home_field.iswithdraw:
		var signalbus = get_node("/root/Game/Signalbus")
		if signalbus.is_player_turn and signalbus.actions_this_turn < signalbus.MAX_ACTIONS_PER_TURN:
			turn -= 1
			turn_label.text = str(turn) + " turns"
			signalbus.track_action()
			if turn <= 0:
				queue_free()
		elif signalbus.actions_this_turn >= signalbus.MAX_ACTIONS_PER_TURN:
			print("No actions remaining this turn!")


func _on_gui_input(event):
	state_machine.on_gui_input(event)  # Pass GUI input events to the state machine for processing
func _input(event):
	state_machine.on_input(event) 
func _on_mouse_entered():
	# Handle mouse enter events
	if !home_field.isasset && !home_field.iswithdraw:  # Ahmad: Check if home_field is not an asset or withdrawal
		state_machine.on_mouse_entered()  # Call the on_mouse_entered function in the state machine
		shadow_texture_rect.visible = true  # Show the shadow texture on hover
		$AudioStreamPlayer2D.play()
	elif home_field.isasset:
		pass  # Do nothing if the home_field is an asset
	elif home_field.iswithdraw:
		pass  # Do nothing if the home_field is a withdrawal

func _on_mouse_exited():
	state_machine.on_mouse_exited()  # Call the on_mouse_exited function in the state machine
	shadow_texture_rect.visible = false  # Hide the shadow texture when not hovering

# Function to manage turns
func turns():
	if turn == -1: 
		turn = poseffect[2]
	print(home_field.name)
	if home_field.name == "Assets":
		turn -= 1
		print(turn)
		if turn == 0:
			home_field.call("transfer", self)
			turn = negeffect[2]
	else:
		turn -= 1
		print(turn)
		if turn == 0:
			queue_free()
	turn_label.text = str(turn) + " turns"
@onready var shader_material = card_texture.material

func destroy() -> void:
	card_texture.use_parent_material = false  # Changed to false to use its own material
	if tween_destroy and tween_destroy.is_running():
		tween_destroy.kill()
	%NameLabel.text = " "
	$"turn_label".text = " "
	$positive_effect_label.text = " "
	$negative_effect_label.text = " "
	$Label.text = " "
	tween_destroy = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_destroy.tween_property(shader_material, "shader_parameter/dissolve_value", 0.0, 2.0).from(1.0)
	tween_destroy.parallel().tween_property(shadow_texture_rect, "self_modulate:a", 0.0, 1.0)
	tween_destroy.tween_callback(queue_free)
