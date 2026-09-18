extends StaticBody2D

@export var max_health: int = 120
var health: int

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	var tween := create_tween()
	tween.tween_property($Sprite, "modulate", Color(1.0, 0.35, 0.25), 0.05)
	tween.tween_property($Sprite, "modulate", Color.WHITE, 0.1)
	if health <= 0:
		queue_free()
