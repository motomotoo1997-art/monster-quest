extends Node
class_name CameraEffectsController

@export var camera_path: NodePath

var _shake_strength := 0.0
var _shake_remaining := 0.0
var _shake_duration := 0.0
var _rng := RandomNumberGenerator.new()
var _camera: Camera2D


func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera2D


func _process(delta: float) -> void:
	if _camera == null:
		return
	if _shake_remaining <= 0.0:
		_camera.offset = _camera.offset.lerp(Vector2.ZERO, minf(delta * 18.0, 1.0))
		return
	_shake_remaining = maxf(_shake_remaining - delta, 0.0)
	var ratio := _shake_remaining / maxf(_shake_duration, 0.001)
	var strength := _shake_strength * ratio
	_camera.offset = Vector2(
		_rng.randf_range(-strength, strength),
		_rng.randf_range(-strength, strength)
	)


func shake(strength: float, duration: float) -> void:
	if strength <= 0.0 or duration <= 0.0:
		return
	_shake_strength = maxf(_shake_strength, strength)
	_shake_duration = maxf(_shake_duration, duration)
	_shake_remaining = maxf(_shake_remaining, duration)
