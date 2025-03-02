class_name Card
extends Control

# UI elements references
@onready var label: Label = $Label
@onready var name_label: Label = $NameLabel
@onready var turn_label: Label = $turn_label
@onready var positive_effect_label: Label = $positive_effect_label
@onready var negative_effect_label: Label = $negative_effect_label
@onready var state_machine: CardStateMachine = $CardStateMachine
@onready var drop_point_detector: Area2D = $DropPointDetector  # Detects where card can be dropped
@onready var card_detector: Area2D = $CardsDetector  # Detects other cards
@onready var home_field: Node  # The field this card belongs to
@onready var clickable = true  # If card can be clicked
@onready var shadow_texture_rect: TextureRect = $ColorRect/TextureRect  # Shadow effect
@onready var card_texture: TextureRect = $ColorRect  # Main card texture

# Material references for visual effects
@onready var shader_material = material
@onready var dissolve_material = card_texture.material
@onready var perspective_material = material

# 3D perspective effect parameters
@export var angle_x_max: float = 15.0
@export var angle_y_max: float = 15.0
@export var perspective_strength: float = 45.0

# Animation tweens
var tween_rot: Tween  # For rotation animations
var tween_move: Tween  # For movement animations
var tween_hover: Tween  # For hover effects
var tween_destroy: Tween  # For card destruction animation
var perspective_tween: Tween  # For perspective effects
var initial_rotation: float = 0.0
var target_position: Vector2
var follow_speed: float = 50.0  # How fast card follows mouse
var max_tilt_angle: float = 35.0  # Maximum tilt when dragging
var mouse_start_pos: Vector2  # Starting position for mouse drag

# Card state tracking
var right_click_active: bool = false
var index: int = 0
var is_positive_phase: bool = true  # Whether card is showing positive effects
var must_go_to_assets: bool = true
var if_event: bool = false
var turn: int = -1  # Turns remaining for current effect
var wichevent = -1
var isevent = -1

# Card effect data [description, turns, money, iron, reputation, co2]
var card_positive = [
	["Solar Plant", 2, 10, 0, 5, 0],
	["Wind Farm", 2, 8, -5, 8, 0],
	["Recycling Plant", 3, 5, 10, 3, -2]
]

var card_negative = [
	["Maintenance", 2, -5, -2, 0, 2],
	["Public Protest", 1, -8, 0, -5, 0],
	["Resource Shortage", 2, -3, -8, -2, 1]
]

# Event cards and their effects
var cards_event = [
	{
	"name" :"globalwarming",
	"effect" :[5,-5,-1,-10,5]
	}
	,{
		"name" :"high C02",
		"effect" : [5,10,5,5,10,0]
	},
	{
		"name" :"public outrage",
		"effect" : [5,-10,0,0,0]
	}

]

#	["bankruptcy",5,-10,0,0,0,"ran out of money"],
#	["iron shortage",5,-10,-1,-5,-2,"ran out of resources"]
var card_eventprice =[
	["high CO2",0,-5,-1,-10,-40],
	["public outrage",0,-5,0,-10,0],
	["bankruptcy",0,-20,0,0,0],
	["iron shortage",0,-5,-1,-5,-2],
]

# Current card effect values
var poseffect = ["good status1", 1, 2, 3, 4, 5]
var negeffect = ["bad status1", 1, 2, 3, 4, 5]
var eventeffect = ["event",1,2,3,4,5] 

#var eventprice = ["price",1,2,3,4,5]#placeholder code,probably remove

# Card data definitions with paired positive and negative effects
var card_pairs = [
	{
		"name": "Solar Plant",
		"positive": [2, 10, 0, 5, 0],  # [turns, money, iron, reputation, co2]
		"negative": [4, 0, -10, 0, 3]
	},
	{
		"name": "Wind Farm",
		"positive": [2, 8, 0, 8, 0], # [turns, money, iron, reputation, co2]
		"negative": [3, -4, -15, 0, 1] # [turns, money, iron, reputation, co2]
	},
	{
		"name": "Recycling Plant",
		"positive": [3, 10, 0, 10, -2],
		"negative": [3, 0, -15, 0, 5]
	},
	
	{
		"name": "Resource Shortage",
		"positive": [1, 10, 0, 0, 0],  # [turns, money, iron, reputation, co2]
		"negative": [3, 0, -5, 0, 5]  # [turns, money, iron, reputation, co2]
	},
	
	{
		"name": "Public Protest",
		"positive": [1, 0, 10, 0, 0],  # [turns, money, iron, reputation, co2]
		"negative": [2, -15, 0, -20, 5]  # [turns, money, iron, reputation, co2]
	}
]

# Store the original card data for transfer
var card_data = null
var card_textures = {
	"Solar Plant": preload("res://solar plant.jpg"),
	"Resource Shortage": preload("res://resource shortage.jpg"),
	"Wind Farm": preload("res://wind farm.jpg"),
	"Recycling Plant": preload("res://recycling plant.jpg"),
	"Public Protest": preload("res://public protest.jpg"),
	# You can add other card textures here as they become available
}

# Zoom card variables
var zoom_card: Control = null
var zoom_active: bool = false
var zoom_scale: float = 2.5
var zoom_position: Vector2 = Vector2(800, 100)  # Position on right side of screen

# Add this method to create the zoomed card
func create_zoom_card():
	# Only create zoom card if we're in the hand field
	if home_field and home_field.name == "hand" and !zoom_active and state_machine.current_state.name != "Drag":
		# Create a duplicate of this card for zooming
		zoom_card = duplicate()
		
		# IMPORTANT: Prevent _ready() from running again on the duplicated card
		zoom_card.set_script(null)  # Remove the script to prevent _ready from running
		
		# Manually set up the zoom card appearance
		zoom_card.scale = Vector2(zoom_scale, zoom_scale)
		zoom_card.position = zoom_position
		zoom_card.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't capture mouse events
		
		# Make labels visible on the zoomed card
		var name_label_zoom = zoom_card.get_node("NameLabel")
		var turn_label_zoom = zoom_card.get_node("turn_label")
		var pos_effect_zoom = zoom_card.get_node("positive_effect_label")
		var neg_effect_zoom = zoom_card.get_node("negative_effect_label")
		
		turn_label_zoom.visible = true
		
		# Add to canvas layer for visibility
		var canvas = get_node("/root/Game/Signalbus/CanvasLayer")
		canvas.add_child(zoom_card)
		zoom_active = true




# Add this method to remove the zoomed card
func remove_zoom_card():
	if zoom_card:
		zoom_card.queue_free()
		zoom_card = null
		zoom_active = false

# Then modify the _ready function to handle the texture assignment
func _ready():
	randomize()
	if isevent == -1: #does not work ----------FIX---------------
		# Select random card pair and store it
		var pair_idx = randi() % card_pairs.size()
		card_data = card_pairs[pair_idx]
		
		  # Add this line to ensure turn_label appears above other elements
		turn_label.z_index = 1
			
		 # Make sure it's visible
		turn_label.visible = true
		
		
		# Set initial positive effects
		name_label.text = card_data.name

		turn = card_data.positive[0]
		poseffect = [
			card_data.name,
			card_data.positive[0],  # turns
			card_data.positive[1],  # money
			card_data.positive[2],  # iron
			card_data.positive[3],  # reputation
			card_data.positive[4]   # co2
		]
		
		# Set matching negative effects
		negeffect = [
			card_data.name,
			card_data.negative[0],  # turns
			card_data.negative[1],  # money
			card_data.negative[2],  # iron
			card_data.negative[3],  # reputation
			card_data.negative[4]   # co2
		]
	else: #does not work ----------FIX---------------
		card_data = cards_event
		eventeffect = [
			card_data.name,
			card_data.negative[0],  # turns
			card_data.negative[1],  # money
			card_data.negative[2],  # iron
			card_data.negative[3],  # reputation
			card_data.negative[4]   # co2
		]
	
	# Set card texture based on card name
	if card_textures.has(card_data.name):
		card_texture.texture = card_textures[card_data.name]
	
	# Make labels initially hidden on the regular card
	name_label.visible = false
	turn_label.visible = true
	positive_effect_label.visible = false
	negative_effect_label.visible = false
	
	# Update all labels with current values
	_update_labels()


# Updates card labels based on current state (positive or negative)
func _update_labels():
	turn_label.text = str(turn) + ""
	if is_positive_phase:
		positive_effect_label.text = "+" + str(poseffect[2]) + "$ +" + str(poseffect[3]) + "Fe +" + str(poseffect[4]) + "Rep"
		negative_effect_label.text = str(negeffect[2]) + "$ " + str(negeffect[3]) + "Fe " + str(negeffect[4]) + "Rep"
	else:
		name_label.text = negeffect[0] + " (Maintenance)"
		positive_effect_label.text = str(negeffect[2]) + "$ " + str(negeffect[3]) + "Fe " + str(negeffect[4]) + "Rep"
		negative_effect_label.text = ""

# Move card with mouse when being dragged
func _process(delta):
	if state_machine.current_state.name == "Drag":
		# Ensure zoom is removed when dragging
		remove_zoom_card()
		
		var target = get_global_mouse_position() - pivot_offset
		var direction = target - global_position
		global_position += direction * delta * follow_speed
		
		var mouse_movement = get_global_mouse_position() - mouse_start_pos
		var tilt_angle = clamp(mouse_movement.x * 0.10, -max_tilt_angle, max_tilt_angle)
		rotation_degrees = lerp(rotation_degrees, tilt_angle, delta * 15.0)

# Handle mouse input on the card
func _on_gui_input(event):
	if event.is_action_pressed("mouse_left"):
		mouse_start_pos = get_global_mouse_position()
		# Remove zoom card when dragging starts
		remove_zoom_card()
	
	state_machine.on_gui_input(event)
	
	if not event is InputEventMouseMotion: return
	
	# Calculate 3D perspective effect based on mouse position
	#var mouse_pos: Vector2 = get_local_mouse_position()
	
	#var lerp_val_x: float = remap(mouse_pos.x, 0.0, size.x, 0, 1)
	#var lerp_val_y: float = remap(mouse_pos.y, 0.0, size.y, 0, 1)

	#var rot_x: float = rad_to_deg(lerp_angle(-angle_x_max, angle_x_max, lerp_val_x)) / 5
	#var rot_y: float = rad_to_deg(lerp_angle(angle_y_max, -angle_y_max, lerp_val_y)) / 5
	
	# Apply 3D perspective shader parameters
	#shader_material.set_shader_parameter("fov", 90.0)
	#shader_material.set_shader_parameter("cull_back", false)
	#shader_material.set_shader_parameter("inset", 0.1)
	#shader_material.set_shader_parameter("y_rot", rot_x)
	#shader_material.set_shader_parameter("x_rot", rot_y)
	
	#shader_material.set_shader_parameter("x_rot", shader_material.get_shader_parameter("x_rot") + 180.0)

# Pass input events to state machine
func _input(event):
	state_machine.on_input(event)
	
	# Remove zoom card if state changes to Drag
	if state_machine.current_state and state_machine.current_state.name == "Drag" and zoom_active:
		remove_zoom_card()

# Handle card destruction with dissolve animation
func destroy() -> void:
	# Remove zoom if active
	remove_zoom_card()
	
	# Ensure we're using the dissolve material
	card_texture.use_parent_material = false
	if tween_destroy and tween_destroy.is_running():
		tween_destroy.kill()
	
	# Clear all labels
	name_label.text = " "
	turn_label.text = " "
	positive_effect_label.text = " "
	negative_effect_label.text = " "
	label.text = " "
	
	# Animate dissolve effect
	tween_destroy = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_destroy.tween_property(dissolve_material, "shader_parameter/dissolve_value", 1.0, 1.0).from(0.0)
	tween_destroy.parallel().tween_property(shadow_texture_rect, "self_modulate:a", 0.0, 1.0)
	tween_destroy.tween_callback(queue_free)

# Process turns for the card
func turns():
	if(home_field.name != "Events"):
		if home_field.name == "Assets" and is_positive_phase:
			turn -= 1
			print("Positive effect turn remaining: ", turn)
			if turn <= 0:
				is_positive_phase = false
				turn = negeffect[1]
				_update_labels()
				home_field.call("transfer", self)
		elif home_field.name == "Withdraw":
			turn -= 1
			print("Negative effect turn remaining: ", turn)
			if turn <= 0:
				destroy()
		
		turn_label.text = str(turn) + ""
	else:
		turn -= 1
		
		if turn <= 0:
			destroy()

# Smoothly move card to target position
func smooth_move_to(target: Vector2):
	# Remove zoom when card is moved
	remove_zoom_card()
	
	if tween_move:
		tween_move.kill()
	tween_move = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_move.tween_property(self, "global_position", target, 0.8)
	
	if tween_rot:
		tween_rot.kill()
	tween_rot = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_rot.tween_property(self, "rotation_degrees", 0, 0.3)

# Mouse enter hover effect
func _on_mouse_entered():
	if home_field:
		# Show zoom card only if in hand field and not in Drag state
		if home_field.name == "hand" and state_machine.current_state.name != "Drag":
			create_zoom_card()
		
		# Only show hover effects for cards not in withdraw or assets fields
		if !home_field.iswithdraw and !home_field.isasset and !home_field.isevent:
			state_machine.on_mouse_entered()
			shadow_texture_rect.visible = true
			
			if tween_hover:
				tween_hover.kill()
			tween_hover = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween_hover.tween_property(self, "scale", Vector2(1.2, 1.1), 0.2)
			
			$AudioStreamPlayer2D.play()
		# For withdraw field, only show minimal hover effect for right-click functionality
		elif home_field.iswithdraw:
			state_machine.on_mouse_entered()

# Mouse exit effect
func _on_mouse_exited():
	# Remove zoom card when mouse exits the card
	remove_zoom_card()
	
	state_machine.on_mouse_exited()
	shadow_texture_rect.visible = false
	
	if tween_hover:
		tween_hover.kill()
	tween_hover = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_hover.tween_property(self, "scale", Vector2(1, 1), 0.15)
