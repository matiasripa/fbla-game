class_name Field
extends MarginContainer

@onready var card_drop_area_right: Area2D = $CardDropAreaRight
@onready var card_drop_area_left: Area2D = $CardDropAreaLeft
@onready var cards_holder: HBoxContainer = $CardsHolder


@export var isasset: bool = false
@export var iswithdraw: bool = false
@export var isevent: bool = false
var cardResource = preload("res://example/card/card.tscn")
signal transfercard(card)
# Card values: [description of the card, amount of turns, money, iron, reputation, CO2]


func _ready():
	$Label.text = name
	
	for child in cards_holder.get_children():
		var card := child as Card
		card.home_field = self

func return_card_starting_position(card: Card):
	card.reparent(cards_holder)
	cards_holder.move_child(card, card.index)

func set_new_card(card: Card):
	card_reposition(card)
	card.home_field = self

func card_reposition(card: Card):
	var field_areas = card.drop_point_detector.get_overlapping_areas()
	var cards_areas = card.card_detector.get_overlapping_areas()
	var index: int = 0
	
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

	card.reparent(cards_holder)
	cards_holder.move_child(card, index)

func _on_button_pressed() -> void:
	print("Cards drawn")
	
	
	
	
	
	
	
	var card = cardResource.instantiate()  # Ahmad: Create an instance of the card resource.
	cards_holder.add_child(card)  # Ahmad: Add the new card instance to the cards holder.
	set_new_card(card)  # Ahmad: Call set_new_card to reposition and set the home field for the new card.



func end_turn():
	var active_cards = cards_holder.get_children()#gives array[node]
	if active_cards.size() == 0:
		print("nothing in "+ name)
	for cards in active_cards:
		print(cards.name)
		if cards.has_method("turns"):
			print("got turns")
			cards.call("turns")

func transfer(card):
	emit_signal("transfercard",card)
	pass
	
	
	


	
