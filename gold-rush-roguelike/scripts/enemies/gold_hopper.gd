extends EnemyBase
class_name GoldHopper

@export_range(0.2, 5.0, 0.05) var hop_interval: float = 1.1
@export_range(0.05, 1.0, 0.01) var hop_duration: float = 0.22
@export_range(1.0, 6.0, 0.1) var hop_speed_multiplier: float = 2.6
@export_range(0.05, 0.5, 0.01) var anticipation_window: float = 0.18

var _hop_cooldown_remaining := 0.0
var _hop_remaining := 0.0
var _hop_direction := Vector2.RIGHT
var _was_hopping := false
var _landing_pulse_remaining := 0.0
var _shadow_base_scale := Vector2.ONE

@onready var ground_shadow: Polygon2D = $Shadow


func _ready() -> void:
	super._ready()
	_shadow_base_scale = ground_shadow.scale


func _tick_behavior(delta: float) -> void:
	var target := choose_target()
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if _hop_remaining > 0.0:
		_hop_remaining = maxf(_hop_remaining - delta, 0.0)
		velocity = _hop_direction * move_speed * hop_speed_multiplier + _get_separation_force()
		if global_position.distance_to(target.global_position) <= attack_range * 1.25:
			_try_contact_attack(target)
		move_and_slide()
		return
	_hop_cooldown_remaining = maxf(_hop_cooldown_remaining - delta, 0.0)
	if _hop_cooldown_remaining <= 0.0 and movement_enabled:
		_hop_direction = global_position.direction_to(target.global_position)
		_hop_remaining = hop_duration
		_hop_cooldown_remaining = hop_interval
	velocity = _get_separation_force() * 0.35
	move_and_slide()


func _update_visual(delta: float) -> void:
	if visual_sprite == null:
		return
	_visual_time += delta
	_landing_pulse_remaining = maxf(_landing_pulse_remaining - delta, 0.0)
	if absf(velocity.x) > 2.0:
		visual_sprite.flip_h = velocity.x < 0.0

	var hopping := _hop_remaining > 0.0
	if _was_hopping and not hopping:
		_landing_pulse_remaining = 0.13
	_was_hopping = hopping

	if hopping:
		if visual_sprite.animation != &"hop":
			visual_sprite.play(&"hop")
		var progress := clampf(1.0 - _hop_remaining / maxf(hop_duration, 0.001), 0.0, 1.0)
		var arc := sin(progress * PI)
		visual_sprite.position = _visual_base_position + Vector2(0.0, -24.0 * arc)
		var stretch := 1.0 + 0.14 * arc
		visual_sprite.scale = Vector2(_visual_base_scale.x / stretch, _visual_base_scale.y * stretch)
		ground_shadow.scale = _shadow_base_scale * Vector2(1.0 - 0.34 * arc, 1.0 - 0.48 * arc)
		ground_shadow.modulate = Color(1.0, 1.0, 1.0, 1.0 - 0.48 * arc)
		return

	if visual_sprite.animation != &"idle":
		visual_sprite.play(&"idle")
	ground_shadow.modulate = Color.WHITE
	var windup := 1.0 - clampf(_hop_cooldown_remaining / maxf(anticipation_window, 0.01), 0.0, 1.0)
	var landing := clampf(_landing_pulse_remaining / 0.13, 0.0, 1.0)
	var crouch := (sin(_visual_time * 5.5) + 1.0) * 0.5
	var squash := maxf(windup * 0.11, landing * 0.14)
	visual_sprite.position = _visual_base_position + Vector2(0.0, 1.25 * crouch + squash * 22.0)
	visual_sprite.scale = Vector2(
		_visual_base_scale.x * (1.0 + 0.025 * crouch + squash),
		_visual_base_scale.y * (1.0 - 0.025 * crouch - squash * 0.72)
	)
	ground_shadow.scale = _shadow_base_scale * Vector2(1.0 + squash * 0.26, 1.0 + squash * 0.10)
