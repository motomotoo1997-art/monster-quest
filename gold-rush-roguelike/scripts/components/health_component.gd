extends Node
class_name HealthComponent

signal health_changed(current: float, maximum: float)
signal died

@export_range(1.0, 100000.0, 1.0) var max_health: float = 100.0

var current_health: float = 0.0
var _death_emitted := false


func _ready() -> void:
	reset_health()


func damage(amount: float) -> void:
	if amount <= 0.0 or is_dead():
		return
	current_health = clampf(current_health - amount, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0 and not _death_emitted:
		_death_emitted = true
		died.emit()


func heal(amount: float) -> void:
	if amount <= 0.0 or is_dead():
		return
	var next_health := clampf(current_health + amount, 0.0, max_health)
	if is_equal_approx(next_health, current_health):
		return
	current_health = next_health
	health_changed.emit(current_health, max_health)


func reset_health() -> void:
	current_health = max_health
	_death_emitted = false
	health_changed.emit(current_health, max_health)


func is_dead() -> bool:
	return current_health <= 0.0 and _death_emitted
