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
var _shadow_base_scale := Vector2.ONE

@onready var weapon_component: WeaponComponent = $WeaponComponent
@onready var muzzle: Marker2D = $Muzzle
@onready var ground_shadow: Polygon2D = $Shadow
@onready var engine_glow: Polygon2D = $EngineGlow
@onready var attack_halo: Polygon2D = $AttackHalo


func _ready() -> void:
	super._ready()
	# Flying discs intentionally render over ground props instead of taking part
	# in ground Y-sort occlusion.
	z_index = 7
	_strafe_sign = -1.0 if get_instance_id() % 2 == 0 else 1.0
	_shadow_base_scale = ground_shadow.scale
	attack_halo.visible = false


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


func _update_visual(delta: float) -> void:
	if visual_sprite == null:
		return
	_visual_time += delta
	if absf(velocity.x) > 2.0:
		visual_sprite.flip_h = velocity.x < 0.0
	var attacking := _burst_shots_remaining > 0
	var next_animation: StringName
	if attacking:
		next_animation = &"attack"
	elif velocity.length() > 8.0:
		next_animation = &"move"
	else:
		next_animation = &"idle"
	if visual_sprite.animation != next_animation:
		visual_sprite.play(next_animation)

	var hover := sin(_visual_time * 5.3 + float(get_instance_id() % 7))
	var hover01 := (hover + 1.0) * 0.5
	visual_sprite.position = _visual_base_position + Vector2(0.0, hover * 5.5)
	var tilt := clampf(velocity.x / maxf(move_speed, 1.0), -1.0, 1.0)
	visual_sprite.rotation = tilt * 0.13
	var pulse := 1.0 + sin(_visual_time * 7.0) * 0.018
	visual_sprite.scale = _visual_base_scale * pulse

	ground_shadow.scale = _shadow_base_scale * Vector2(0.92 + (1.0 - hover01) * 0.16, 0.78 + (1.0 - hover01) * 0.18)
	ground_shadow.modulate = Color(1.0,1.0,1.0,0.56 + (1.0 - hover01) * 0.34)
	engine_glow.position = Vector2(0.0, -29.0 + hover * 2.2)
	engine_glow.scale = Vector2(1.0 + pulse * 0.055, 0.92 + hover01 * 0.12)
	engine_glow.modulate = Color(1.0,1.0,1.0,0.68 + hover01 * 0.28)

	attack_halo.visible = attacking
	if attacking:
		var attack_pulse := 0.5 + 0.5 * sin(_visual_time * 22.0)
		attack_halo.scale = Vector2.ONE * (0.74 + attack_pulse * 0.28)
		attack_halo.rotation = _visual_time * 1.8
		attack_halo.modulate = Color(1.0,1.0,1.0,0.50 + attack_pulse * 0.50)


func _fire_at(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	weapon_component.try_fire(
		muzzle.global_position,
		muzzle.global_position.direction_to(target.global_position),
		team_component.team
	)
