extends Node2D
class_name SimpleBurstVFX

@export_range(0.05, 3.0, 0.05) var duration: float = 0.28
@export_range(0.1, 5.0, 0.1) var end_scale: float = 1.8
@export_range(-8.0, 8.0, 0.1) var spin_speed: float = 1.4

var _elapsed := 0.0
var _start_scale := Vector2.ONE
var _light: PointLight2D
var _start_light_energy := 0.0


func _ready() -> void:
	_start_scale = scale
	for child in get_children():
		if child is PointLight2D:
			_light = child as PointLight2D
			_start_light_energy = _light.energy
			break


func _process(delta: float) -> void:
	_elapsed += delta
	var t := clampf(_elapsed / maxf(duration, 0.001), 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 2.0)
	scale = _start_scale.lerp(_start_scale * end_scale, eased)
	rotation += spin_speed * delta * (1.0 - t)
	modulate.a = 1.0 - t
	if _light != null:
		var flash_curve := (1.0 - t) * (0.82 + 0.18 * sin(t * PI * 5.0))
		_light.energy = maxf(_start_light_energy * flash_curve, 0.0)
		_light.texture_scale = maxf(_light.texture_scale * (1.0 + delta * 0.55), 0.01)
	if t >= 1.0:
		queue_free()
