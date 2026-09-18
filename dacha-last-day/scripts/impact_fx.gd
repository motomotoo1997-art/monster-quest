extends Node2D

@export var lifetime := 0.16
var remaining := 0.16
var hit_stream: AudioStream

func _ready() -> void:
	remaining = lifetime
	if ResourceLoader.exists("res://audio/hit.wav"):
		hit_stream = load("res://audio/hit.wav") as AudioStream
		var player := AudioStreamPlayer2D.new()
		player.stream = hit_stream
		player.volume_db = -7.0
		add_child(player)
		player.play()
	queue_redraw()

func _process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress := 1.0 - clampf(remaining / lifetime, 0.0, 1.0)
	var radius := 5.0 + progress * 18.0
	var alpha := 1.0 - progress
	for i in 8:
		var direction := Vector2.RIGHT.rotated(TAU * float(i) / 8.0)
		draw_line(direction * radius * 0.35, direction * radius, Color(1.0, 0.72, 0.25, alpha), 2.5)
	draw_circle(Vector2.ZERO, maxf(2.0, 6.0 * (1.0 - progress)), Color(1.0, 0.96, 0.72, alpha))
