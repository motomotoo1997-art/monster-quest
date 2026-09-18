extends StaticBody2D

signal destroyed

@export var max_health: int = 500
var health: int
var active := false

func _ready() -> void:
	health = max_health

func set_active(value: bool) -> void:
	active = value
	$CoreVisual.visible = active

func take_damage(amount: int) -> void:
	if not active:
		return
	health = maxi(0, health - amount)
	var tween := create_tween()
	tween.tween_property($CoreVisual, "modulate", Color(1.0, 0.25, 0.2), 0.06)
	tween.tween_property($CoreVisual, "modulate", Color.WHITE, 0.12)
	if health <= 0:
		destroyed.emit()
		get_tree().reload_current_scene()
