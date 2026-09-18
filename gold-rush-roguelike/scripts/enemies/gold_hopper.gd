extends EnemyBase
class_name GoldHopper

@export_range(0.2, 5.0, 0.05) var hop_interval: float = 1.1
@export_range(0.05, 1.0, 0.01) var hop_duration: float = 0.22
@export_range(1.0, 6.0, 0.1) var hop_speed_multiplier: float = 2.6

var _hop_cooldown_remaining := 0.0
var _hop_remaining := 0.0
var _hop_direction := Vector2.RIGHT


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
