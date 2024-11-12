class_name Field
extends MarginContainer


@onready var card_drop_area_right: Area2D = $CardDropAreaRight
@onready var card_drop_area_left: Area2D = $CardDropAreaLeft
@onready var cards_holder: HBoxContainer = $CardsHolder

var cardResource = preload("res://example/card/card.tscn")

#this is the card values,add more interesting values
#["description of the card",amount of turns,money,iron,reputation,C02]
var card_positive = [["good status1",1,2,3,4,5],["goodstatus2",1,2,3,4,5],["goodstatus2",1,2,3,4,5]]
var card_negative = [["bad status1",1,2,3,4,5],["bad status2",1,2,3,4,5],["bad status2",1,2,3,4,5]]
var positiverand = 0
var negativerand = 0

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
		print(field_areas.has(card_drop_area_left))
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
	print("cards drawed")
	var cardpos
	var cardneg
	cardvalueselector(cardpos,cardneg)
	
	var card = cardResource.instantiate()
	cards_holder.add_child(card)

	
	
	
	

func cardvalueselector(positive_value,negative_value):
	positive_value = card_positive[randf_range(0,card_positive.size())]
	negative_value = card_negative[randf_range(0,card_negative.size())]
	print(positive_value)
	print(negative_value)
