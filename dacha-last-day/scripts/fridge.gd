extends Area2D

@export var heal_per_tick: int = 4
@export var tick_interval: float = 1.0
var clock := 0.0

func _physics_process(delta: float) -> void:
	clock -= delta
	if clock > 0.0:
		return
	clock = tick_interval
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("heal"):
			body.heal(heal_per_tick)
