extends MarginContainer

const example_scene = preload("res://example/example.tscn")

# Declare selector variables
var selector_one
var selector_two
var selector_four

var current_selection = 0
var popup

func _ready():
	# Initialize selectors
	selector_one = $CenterContainer/VBoxContainer/CenterContainer2/VBoxContainer/CenterContainer/HBoxContainer/Selector
	selector_two = $CenterContainer/VBoxContainer/CenterContainer2/VBoxContainer/CenterContainer2/HBoxContainer/Selector
	selector_four = $CenterContainer/VBoxContainer/CenterContainer2/VBoxContainer/CenterContainer4/HBoxContainer/Selector
	
	# Set up the how to play popup
	popup = $HowToPlayPopup
	$HowToPlayPopup/MarginContainer/VBoxContainer/CloseButton.connect("pressed", _on_close_button_pressed)
	
	set_current_selection(0)

func _process(delta):
	if Input.is_action_just_pressed("ui_down") and current_selection < 2:
		current_selection += 1
		set_current_selection(current_selection)
	elif Input.is_action_just_pressed("ui_up") and current_selection > 0:
		current_selection -= 1
		set_current_selection(current_selection)
	elif Input.is_action_just_pressed("ui_accept"):
		handle_selection(current_selection)

func handle_selection(_current_selection):
	if _current_selection == 0:
		get_parent().add_child(example_scene.instantiate())  # Use instantiate() for Godot 4.x
		queue_free()
	elif _current_selection == 1:
		# Show How to Play popup
		popup.popup_centered()
	elif _current_selection == 2:
		get_tree().quit()

func set_current_selection(_current_selection):
	selector_one.text = ""
	selector_two.text = ""
	selector_four.text = ""
	
	if _current_selection == 0:
		selector_one.text = ">"
	elif _current_selection == 1:
		selector_two.text = ">"
	elif _current_selection == 2:
		selector_four.text = ">"

func _on_close_button_pressed():
	popup.hide()
