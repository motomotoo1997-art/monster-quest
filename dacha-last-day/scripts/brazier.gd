extends Area2D

@export var damage: int = 8
@export var tick_interval: float = 0.42
var clock := 0.0

func _physics_process(delta: float) -> void:
	clock -= delta
	if clock > 0.0:
		return
	clock = tick_interval
	for body in get_overlapping_bodies():
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(damage)
