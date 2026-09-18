extends Node
class_name EconomyController

signal gold_changed(total: int)

@export_range(0, 100000, 1) var starting_gold: int = 0

var gold: int = 0
var pickup_value_multiplier: float = 1.0


func _ready() -> void:
	add_to_group("economy_controller")
	gold = starting_gold
	gold_changed.emit(gold)


func reset() -> void:
	gold = starting_gold
	pickup_value_multiplier = 1.0
	gold_changed.emit(gold)


func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	var adjusted := maxi(int(round(float(amount) * pickup_value_multiplier)), 1)
	gold += adjusted
	gold_changed.emit(gold)


func can_afford(cost: int) -> bool:
	return cost >= 0 and gold >= cost


func spend_gold(cost: int) -> bool:
	if cost < 0 or not can_afford(cost):
		return false
	if cost == 0:
		return true
	gold -= cost
	gold_changed.emit(gold)
	return true


func multiply_pickup_value(multiplier: float) -> void:
	pickup_value_multiplier = maxf(pickup_value_multiplier * multiplier, 0.0)
