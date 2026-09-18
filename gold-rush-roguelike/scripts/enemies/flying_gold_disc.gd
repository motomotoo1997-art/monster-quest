extends EnemyBase
class_name FlyingGoldDisc

@export_range(60.0, 600.0, 5.0) var strafe_distance: float = 215.0
@export_range(0.2, 8.0, 0.05) var burst_interval: float = 1.9
@export_range(1, 8, 1) var burst_count: int = 3
@export_range(0.03, 1.0, 0.01) var burst_gap: float = 0.13

var _shot_cooldown_remaining := 0.65
var _burst_shots_remaining := 0
var _burst_timer := 0.0
var _strafe_sign := 1.0

@onready var weapon_component: WeaponComponent = $WeaponComponent
@onready var muzzle: Marker2D = $Muzzle


func _ready() -> void:
	super()
	_strafe_sign = -1.0 if get_instance_id() % 2 == 0 else 1.0


func _tick_behavior(delta: float) -> void:
	var target := choose_target()
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var offset := target.global_position - global_position
	var distance := maxf(offset.length(), 0.001)
	var radial := offset / distance
	var tangent := radial.orthogonal() * _strafe_sign
	var radial_correction := clampf((distance - strafe_distance) / strafe_distance, -0.8, 0.8)
	velocity = (tangent + radial * radial_correction).normalized() * move_speed
	move_and_slide()

	if _burst_shots_remaining > 0:
		_burst_timer = maxf(_burst_timer - delta, 0.0)
		if _burst_timer <= 0.0:
			_fire_at(target)
			_burst_shots_remaining -= 1
			_burst_timer = burst_gap
			if _burst_shots_remaining <= 0:
				_shot_cooldown_remaining = burst_interval
		return

	_shot_cooldown_remaining = maxf(_shot_cooldown_remaining - delta, 0.0)
	if _shot_cooldown_remaining <= 0.0 and distance <= attack_range:
		_burst_shots_remaining = burst_count
		_burst_timer = 0.0


func _fire_at(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	weapon_component.try_fire(
		muzzle.global_position,
		muzzle.global_position.direction_to(target.global_position),
		team_component.team
	)
