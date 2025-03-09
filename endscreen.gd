extends MarginContainer

# Updated path to match the actual location of your scene file
const exampl_scene = preload("res://example/example.tscn")

# Preload the different end screen backgrounds
var co2_loss_texture = preload("res://example/Co2 end .jpg")
var money_loss_texture = preload("res://example/unbalanced end.jpg")
var reputation_loss_texture = preload("res://example/unbalanced end.jpg")
var victory_texture = preload("res://example/win.jpg")

# Declare selector variables
var selector_one
var selector_two

# Game over reason
var game_over_reason = ""
var game_over_message = ""

var current_selection = 0

func _ready():
	# Initialize selectors
	selector_one = $CenterContainer/VBoxContainer/CenterContainer2/VBoxContainer/CenterContainer/HBoxContainer/Selector
	selector_two = $CenterContainer/VBoxContainer/CenterContainer2/VBoxContainer/CenterContainer2/HBoxContainer/Selector
	
	# Set the background based on game over reason
	set_background()
	
	set_current_selection(0)

func set_background():
	var background = $TextureRect
	
	# Set texture based on game over reason
	if game_over_reason == "co2":
		background.texture = co2_loss_texture
	elif game_over_reason == "money":
		background.texture = money_loss_texture
	elif game_over_reason == "reputation":
		background.texture = reputation_loss_texture
	elif game_over_reason == "victory":
		background.texture = victory_texture
	else:
		# Default case if no specific reason is provided
		background.texture = money_loss_texture

func _process(delta):
	if Input.is_action_just_pressed("ui_down") and current_selection < 1:
		current_selection += 1
		set_current_selection(current_selection)
	elif Input.is_action_just_pressed("ui_up") and current_selection > 0:
		current_selection -= 1
		set_current_selection(current_selection)
	elif Input.is_action_just_pressed("ui_accept"):
		handle_selection(current_selection)

func handle_selection(_current_selection):
	if _current_selection == 0:
		# Completely restart the game
		restart_game()
	elif _current_selection == 1:
		get_tree().quit()

func restart_game():
	# First, make sure we clean up the current scene
	queue_free()
	
	# Then create a brand new game scene instance and add it to the scene tree
	var new_game = load("res://example/example.tscn").instantiate()
	
	# Add it to the root
	get_tree().root.add_child(new_game)
	
	# Important: Set as current scene AFTER adding to tree
	get_tree().current_scene = new_game
	
	# Allow one frame to process before continuing
	await get_tree().process_frame


func set_current_selection(_current_selection):
	selector_one.text = ""
	selector_two.text = ""
	
	if _current_selection == 0:
		selector_one.text = ">"
	elif _current_selection == 1:
		selector_two.text = ">"
