extends EnemyBase
class_name GoldCoinSentinel

@export_range(40.0, 800.0, 5.0) var preferred_distance: float = 260.0
@export_range(0.1, 2.0, 0.05) var telegraph_time: float = 0.55
@export_range(0.2, 8.0, 0.05) var shot_interval: float = 1.65

var _telegraph_remaining := 0.0
var _shot_cooldown_remaining := 0.4
var _attack_visual_remaining := 0.0
var _shadow_base_scale := Vector2.ONE

@onready var weapon_component: WeaponComponent = $WeaponComponent
@onready var muzzle: Marker2D = $Muzzle
@onready var telegraph_visual: Polygon2D = $Telegraph
@onready var telegraph_core: Polygon2D = $TelegraphCore
@onready var emitter_glow: Polygon2D = $EmitterGlow
@onready var ground_shadow: Polygon2D = $Shadow


func _ready() -> void:
	super._ready()
	_shadow_base_scale = ground_shadow.scale
	telegraph_visual.visible = false
	telegraph_core.visible = false
	emitter_glow.visible = false


func _tick_behavior(delta: float) -> void:
	_attack_visual_remaining = maxf(_attack_visual_remaining - delta, 0.0)
	var target := choose_target()
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_shot_cooldown_remaining = maxf(_shot_cooldown_remaining - delta, 0.0)
	if _telegraph_remaining > 0.0:
		_telegraph_remaining = maxf(_telegraph_remaining - delta, 0.0)
		velocity = _get_separation_force() * 0.4
		move_and_slide()
		if _telegraph_remaining <= 0.0:
			_fire_at(target)
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	if distance > preferred_distance + 35.0:
		_move_toward(target.global_position, 0.75)
	elif distance < preferred_distance - 45.0 and movement_enabled:
		velocity = -offset.normalized() * move_speed * 0.75 + _get_separation_force()
	else:
		velocity = offset.normalized().orthogonal() * move_speed * 0.3 + _get_separation_force()
	move_and_slide()
	if distance <= attack_range and _shot_cooldown_remaining <= 0.0:
		_telegraph_remaining = telegraph_time
		telegraph_visual.visible = true
		telegraph_core.visible = true
		emitter_glow.visible = true


func _update_visual(delta: float) -> void:
	if visual_sprite == null:
		return
	_visual_time += delta
	if absf(velocity.x) > 2.0:
		visual_sprite.flip_h = velocity.x < 0.0
	var charging := _telegraph_remaining > 0.0
	var firing := _attack_visual_remaining > 0.0
	var next_animation: StringName
	if charging or firing:
		next_animation = &"attack"
	elif velocity.length() > 10.0:
		next_animation = &"move"
	else:
		next_animation = &"idle"
	if visual_sprite.animation != next_animation:
		visual_sprite.play(next_animation)

	var moving := velocity.length() > 8.0
	var bob := sin(_visual_time * 7.0) * 1.3 if moving else sin(_visual_time * 3.2) * 0.45
	var recoil := 0.0
	if firing:
		recoil = clampf(_attack_visual_remaining / 0.24, 0.0, 1.0)
	visual_sprite.position = _visual_base_position + Vector2((-6.0 if not visual_sprite.flip_h else 6.0) * recoil, bob - recoil * 1.5)
	visual_sprite.scale = Vector2(
		_visual_base_scale.x * (1.0 + recoil * 0.035),
		_visual_base_scale.y * (1.0 - recoil * 0.035)
	)
	ground_shadow.scale = _shadow_base_scale * Vector2(1.0 + recoil * 0.06, 1.0 - recoil * 0.03)

	if charging:
		var charge_progress := 1.0 - clampf(_telegraph_remaining / maxf(telegraph_time, 0.01), 0.0, 1.0)
		var pulse := 0.5 + 0.5 * sin(_visual_time * 18.0)
		telegraph_visual.visible = true
		telegraph_core.visible = true
		emitter_glow.visible = true
		telegraph_visual.rotation = _visual_time * 1.1
		telegraph_core.rotation = -_visual_time * 1.65
		telegraph_visual.scale = Vector2.ONE * (0.82 + charge_progress * 0.26 + pulse * 0.04)
		telegraph_core.scale = Vector2.ONE * (0.68 + charge_progress * 0.34 + pulse * 0.07)
		telegraph_visual.modulate = Color(1.0,1.0,1.0,0.58 + charge_progress * 0.42)
		telegraph_core.modulate = Color(1.0,1.0,1.0,0.64 + pulse * 0.36)
		emitter_glow.scale = Vector2.ONE * (0.68 + charge_progress * 0.52 + pulse * 0.12)
		emitter_glow.modulate = Color(1.0,1.0,1.0,0.62 + charge_progress * 0.38)
	elif firing:
		telegraph_visual.visible = false
		telegraph_core.visible = false
		emitter_glow.visible = true
		var fire_pulse := clampf(_attack_visual_remaining / 0.24, 0.0, 1.0)
		emitter_glow.scale = Vector2.ONE * (0.65 + fire_pulse * 0.85)
		emitter_glow.modulate = Color(1.0,1.0,1.0,fire_pulse)
	else:
		telegraph_visual.visible = false
		telegraph_core.visible = false
		emitter_glow.visible = false


func _fire_at(target: Node2D) -> void:
	telegraph_visual.visible = false
	telegraph_core.visible = false
	_attack_visual_remaining = 0.24
	emitter_glow.visible = true
	if target == null or not is_instance_valid(target):
		_shot_cooldown_remaining = shot_interval
		return
	weapon_component.try_fire(
		muzzle.global_position,
		muzzle.global_position.direction_to(target.global_position),
		team_component.team
	)
	_shot_cooldown_remaining = shot_interval
