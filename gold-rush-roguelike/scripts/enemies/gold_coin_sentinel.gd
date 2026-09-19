extends EnemyBase
class_name GoldCoinSentinel

@export_range(40.0, 800.0, 5.0) var preferred_distance: float = 260.0
@export_range(0.1, 2.0, 0.05) var telegraph_time: float = 0.55
@export_range(0.2, 8.0, 0.05) var shot_interval: float = 1.65

var _telegraph_remaining := 0.0
var _shot_cooldown_remaining := 0.4
var _attack_visual_remaining := 0.0

@onready var weapon_component: WeaponComponent = $WeaponComponent
@onready var muzzle: Marker2D = $Muzzle
@onready var telegraph_visual: CanvasItem = $Telegraph


func _ready() -> void:
	super()
	telegraph_visual.visible = false


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


func _update_visual(delta: float) -> void:
	if visual_sprite == null:
		return
	_visual_time += delta
	if absf(velocity.x) > 2.0:
		visual_sprite.flip_h = velocity.x < 0.0
	var next_animation: StringName
	if _telegraph_remaining > 0.0 or _attack_visual_remaining > 0.0:
		next_animation = &"attack"
	elif velocity.length() > 10.0:
		next_animation = &"move"
	else:
		next_animation = &"idle"
	if visual_sprite.animation != next_animation:
		visual_sprite.play(next_animation)
	var moving := velocity.length() > 8.0
	var bob := sin(_visual_time * 7.0) * 1.3 if moving else sin(_visual_time * 3.2) * 0.45
	visual_sprite.position = _visual_base_position + Vector2(0.0, bob)
	visual_sprite.scale = _visual_base_scale


func _fire_at(target: Node2D) -> void:
	telegraph_visual.visible = false
	_attack_visual_remaining = 0.24
	if target == null or not is_instance_valid(target):
		_shot_cooldown_remaining = shot_interval
		return
	weapon_component.try_fire(
		muzzle.global_position,
		muzzle.global_position.direction_to(target.global_position),
		team_component.team
	)
	_shot_cooldown_remaining = shot_interval
