class_name Card
extends Control

@onready var label: Label = $Label
@onready var name_label: Label = $NameLabel
@onready var turn_label: Label = $turn_label
@onready var positive_effect_label: Label = $positive_effect_label
@onready var negative_effect_label: Label = $negative_effect_label
@onready var state_machine: CardStateMachine = $CardStateMachine
@onready var drop_point_detector: Area2D = $DropPointDetector
@onready var card_detector: Area2D = $CardsDetector
@onready var home_field: Node
@onready var clickable = true
@onready var shadow_texture_rect: TextureRect = $ColorRect/TextureRect
@onready var card_texture: TextureRect = $ColorRect
# Correct material references to use the card_texture's material
@onready var shader_material = material
@onready var dissolve_material = card_texture.material
@onready var perspective_material = material

@export var angle_x_max: float = 15.0
@export var angle_y_max: float = 15.0
@export var perspective_strength: float = 45.0

var tween_rot: Tween
var tween_move: Tween
var tween_hover: Tween
var tween_destroy: Tween
var perspective_tween: Tween
var initial_rotation: float = 0.0
var target_position: Vector2
var follow_speed: float = 50.0
var max_tilt_angle: float = 35.0
var mouse_start_pos: Vector2

var right_click_active: bool = false
var index: int = 0
var is_positive_phase: bool = true
var must_go_to_assets: bool = true

var turn: int = -1

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

var poseffect = ["good status1", 1, 2, 3, 4, 5]
var negeffect = ["bad status1", 1, 2, 3, 4, 5]


func _ready():
	randomize()
	
	# Set random card effects
	var pos_idx = randi() % card_positive.size()
	var neg_idx = randi() % card_negative.size()
	poseffect = card_positive[pos_idx]
	negeffect = card_negative[neg_idx]
	
	# Update labels
	name_label.text = poseffect[0]
	turn = poseffect[1]
	turn_label.text = str(turn) + " turns"
	positive_effect_label.text = "+" + str(poseffect[2]) + "$ +" + str(poseffect[3]) + "Fe +" + str(poseffect[4]) + "Rep"
	negative_effect_label.text = str(negeffect[2]) + "$ " + str(negeffect[3]) + "Fe " + str(negeffect[4]) + "Rep"
	
	# Make sure labels don't inherit the perspective material
	name_label.use_parent_material = false
	turn_label.use_parent_material = false
	positive_effect_label.use_parent_material = false
	negative_effect_label.use_parent_material = false
	label.use_parent_material = false

func _process(delta):
	if state_machine.current_state.name == "Drag":
		var target = get_global_mouse_position() - pivot_offset
		var direction = target - global_position
		global_position += direction * delta * follow_speed
		
		var mouse_movement = get_global_mouse_position() - mouse_start_pos
		var tilt_angle = clamp(mouse_movement.x * 0.35, -max_tilt_angle, max_tilt_angle)
		rotation_degrees = lerp(rotation_degrees, tilt_angle, delta * 25.0)

func _on_gui_input(event):
	if event.is_action_pressed("mouse_left"):
		mouse_start_pos = get_global_mouse_position()
	state_machine.on_gui_input(event)
	
	if not event is InputEventMouseMotion: return
	
	var mouse_pos: Vector2 = get_local_mouse_position()
	
	var lerp_val_x: float = remap(mouse_pos.x, 0.0, size.x, 0, 1)
	var lerp_val_y: float = remap(mouse_pos.y, 0.0, size.y, 0, 1)

	var rot_x: float = rad_to_deg(lerp_angle(-angle_x_max, angle_x_max, lerp_val_x)) / 5
	var rot_y: float = rad_to_deg(lerp_angle(angle_y_max, -angle_y_max, lerp_val_y)) / 5
	shader_material.set_shader_parameter("fov", 90.0)
	shader_material.set_shader_parameter("cull_back", false)
	shader_material.set_shader_parameter("inset", 0.1)
	shader_material.set_shader_parameter("y_rot", rot_x)
	shader_material.set_shader_parameter("x_rot", rot_y)
	
	shader_material.set_shader_parameter("x_rot", shader_material.get_shader_parameter("x_rot") + 180.0)

func _input(event):
	state_machine.on_input(event)

func destroy() -> void:
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
	
	tween_destroy = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_destroy.tween_property(dissolve_material, "shader_parameter/dissolve_value", 1.0, 1.0).from(0.0)
	tween_destroy.parallel().tween_property(shadow_texture_rect, "self_modulate:a", 0.0, 1.0)
	tween_destroy.tween_callback(queue_free)

func turns():
	if home_field.name == "Assets" and is_positive_phase:
		turn -= 1
		print("Positive effect turn remaining: ", turn)
		if turn <= 0:
			is_positive_phase = false
			turn = negeffect[1]
			name_label.text = negeffect[0]  # Update name to negative effect
			home_field.call("transfer", self)
			turn_label.text = str(turn) + " turns"
	elif home_field.name == "Withdraw":
		turn -= 1
		print("Negative effect turn remaining: ", turn)
		if turn <= 0:
			destroy()
	
	turn_label.text = str(turn) + " turns"

func smooth_move_to(target: Vector2):
	if tween_move:
		tween_move.kill()
	tween_move = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_move.tween_property(self, "global_position", target, 0.8)
	
	if tween_rot:
		tween_rot.kill()
	tween_rot = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_rot.tween_property(self, "rotation_degrees", 0, 0.3)

func _on_mouse_entered():
	if home_field:
		# Only show hover effects for cards not in withdraw or assets fields
		if !home_field.iswithdraw and !home_field.isasset:
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
			# No visual scaling or shadow effects for withdraw field
func _on_mouse_exited():
	state_machine.on_mouse_exited()
	shadow_texture_rect.visible = false
	
	if tween_hover:
		tween_hover.kill()
	tween_hover = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_hover.tween_property(self, "scale", Vector2(1, 1), 0.15)
