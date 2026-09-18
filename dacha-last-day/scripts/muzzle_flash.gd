extends Node2D

@export var lifetime := 0.09
var remaining := 0.09

func _ready() -> void:
	remaining = lifetime
	queue_redraw()

func _process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		queue_free()
		return
	var ratio := clampf(remaining / lifetime, 0.0, 1.0)
	modulate.a = ratio
	scale = Vector2.ONE * (1.0 + (1.0 - ratio) * 0.35)

func _draw() -> void:
	var outer := PackedVector2Array([Vector2(-7, -5), Vector2(4, -2), Vector2(31, 0), Vector2(4, 2), Vector2(-7, 5), Vector2(-2, 0)])
	var inner := PackedVector2Array([Vector2(-3, -3), Vector2(6, -1), Vector2(21, 0), Vector2(6, 1), Vector2(-3, 3), Vector2(0, 0)])
	draw_colored_polygon(outer, Color(1.0, 0.42, 0.08, 0.92))
	draw_colored_polygon(inner, Color(1.0, 0.92, 0.48, 1.0))
