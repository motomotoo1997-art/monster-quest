extends Node2D
class_name SimpleBurstVFX

@export_range(0.05, 3.0, 0.05) var duration: float = 0.28
@export_range(0.1, 5.0, 0.1) var end_scale: float = 1.8

var _elapsed := 0.0
var _start_scale := Vector2.ONE


func _ready() -> void:
	_start_scale = scale


func _process(delta: float) -> void:
	_elapsed += delta
	var t := clampf(_elapsed / maxf(duration, 0.001), 0.0, 1.0)
	scale = _start_scale.lerp(_start_scale * end_scale, t)
	modulate.a = 1.0 - t
	if t >= 1.0:
		queue_free()
