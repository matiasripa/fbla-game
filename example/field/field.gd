class_name Field
extends MarginContainer

# Area2D nodes that detect card drops
@onready var card_drop_area_right: Area2D = $CardDropAreaRight
@onready var card_drop_area_left: Area2D = $CardDropAreaLeft
@onready var cards_holder: HBoxContainer = $CardsHolder  # Container for cards
@onready var fire_border: ColorRect = $"../destroy/ColorRect" # Reference to the fire border

# Field type flags
@export var isasset: bool = false  # If this is the Assets field
@export var iswithdraw: bool = false  # If this is the Withdraw field
@export var isevent: bool = false  # If this is the Events field
@export var isdestroy: bool = false  # If this is the Destroy field

var cardResource = preload("res://example/card/card.tscn")  # Card scene to instantiate
signal transfercard(card)  # Signal emitted when card transfers to another field
signal eventcard(eventstate)  # Signal emitted for event cards
var wichevent = 0  # Current event type

func _ready():
	$Label.text = name  # Set field label to match node name
	
	# Enable fire border if this is the destroy field
	if isdestroy:
		fire_border.visible = true
		# Make the panel more transparent to see the fire effect better
		$Panel.modulate.a = 0.15
	
	# Set home_field for all existing cards
	for child in cards_holder.get_children():
		var card := child as Card
		card.home_field = self

# Move card back to its original position
func return_card_starting_position(card: Card):
	card.reparent(cards_holder)
	cards_holder.move_child(card, card.index)

# Setup a new card in this field
func set_new_card(card: Card):
	card_reposition(card)
	card.home_field = self
	if isevent == true:
		card.wichevent = eventcard

# Position card in the correct place based on neighboring cards
func card_reposition(card: Card):
	var field_areas = card.drop_point_detector.get_overlapping_areas()
	var cards_areas = card.card_detector.get_overlapping_areas()
	var index: int = 0
	
	# Determine where to place the card based on overlapping areas
	if cards_areas.is_empty():
		if field_areas.has(card_drop_area_right):
			index = cards_holder.get_children().size()
	elif cards_areas.size() == 1:
		if field_areas.has(card_drop_area_left):
			index = cards_areas[0].get_parent().get_index()
		else:
			index = cards_areas[0].get_parent().get_index() + 1
	else:
		index = cards_areas[0].get_parent().get_index()
		if index > cards_areas[1].get_parent().get_index():
			index = cards_areas[1].get_parent().get_index()
		index += 1

	# Reparent card to this field and position at calculated index
	card.reparent(cards_holder)
	cards_holder.move_child(card, index)

# Draw a new card button handler
func _on_button_pressed() -> void:
	# Check if we already have 5 cards in hand
	if cards_holder.get_child_count() >= 5:
		print("Hand is full! Maximum 5 cards allowed.")
		return
		
	print("Cards drawn")
	$"../../../AudioStreamPlayer".play2()
	
	# Create new card instance and add to field
	var card = cardResource.instantiate()  
	cards_holder.add_child(card)  
	set_new_card(card)

# Setup event cards
func event_setup():
	var card = cardResource.instantiate()
	card.if_event = true  # Mark this as an event card
	card.wichevent = wichevent  # Set which event this is
	cards_holder.add_child(card)
	
	# Set the home_field before calling set_new_card to ensure proper shadow handling
	card.home_field = self
	
	# Now call set_new_card which will position the card correctly
	set_new_card(card)
	
	# Explicitly hide the shadow for event cards in event field
	if isevent:
		card.get_node("ColorRect/TextureRect").visible = false
	
# Process turn end for all cards in this field
func end_turn():
	var active_cards = cards_holder.get_children()  # Get array of cards
	if active_cards.size() == 0:
		print("nothing in "+ name)
	for cards in active_cards:
		print(cards.name)
		if cards.has_method("turns"):
			print("got turns")
			cards.call("turns")  # Call turns method on each card

# Transfer card to withdraw field when positive effect ends
func transfer(card: Card):
	# Ensure we're transferring the same card with its negative effects
	if card.is_positive_phase:
		card.is_positive_phase = false
		card.turn = card.negeffect[1]  # Reset turn count to negative effect duration
		card._update_labels()  # Update the card's display
	emit_signal("transfercard", card)  # Signal that card should be transferred
