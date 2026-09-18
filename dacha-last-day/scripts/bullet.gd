extends Area2D

@export var speed: float = 760.0
@export var damage: int = 20
@export var lifetime: float = 1.4

const IMPACT_FX := preload("res://scenes/vfx/impact_fx.tscn")

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += Vector2.RIGHT.rotated(rotation) * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	var impact := IMPACT_FX.instantiate()
	impact.global_position = global_position
	get_tree().current_scene.add_child(impact)
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
