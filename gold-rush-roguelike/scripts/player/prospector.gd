extends CharacterBody2D
class_name Prospector

signal player_died
signal dash_started
signal dash_cooldown_changed(remaining: float, maximum: float)

@export_range(10.0, 2000.0, 1.0) var move_speed: float = 280.0
@export_range(10.0, 5000.0, 1.0) var acceleration: float = 1800.0
@export_range(10.0, 5000.0, 1.0) var deceleration: float = 2200.0
@export_range(50.0, 5000.0, 1.0) var dash_speed: float = 760.0
@export_range(0.05, 2.0, 0.01) var dash_duration: float = 0.16
@export_range(0.1, 10.0, 0.05) var dash_cooldown: float = 1.1
@export_range(0.0, 2.0, 0.01) var dash_invulnerability: float = 0.18
@export_range(0.02, 1.0, 0.01) var attack_pose_hold: float = 0.22
@export_range(0.02, 1.0, 0.01) var hit_pose_hold: float = 0.18
@export_range(0.2, 2.0, 0.05) var death_visual_duration: float = 0.78

var _input_enabled := true
var _dash_remaining := 0.0
var _dash_cooldown_remaining := 0.0
var _invulnerability_remaining := 0.0
var _attack_pose_remaining := 0.0
var _hit_pose_remaining := 0.0
var _last_health := 0.0
var _dash_direction := Vector2.RIGHT
var _dash_cooldown_multiplier := 1.0
var _visual_time := 0.0
var _death_visual_elapsed := 0.0
var _is_dead := false
var _body_base_position := Vector2.ZERO
var _body_base_scale := Vector2.ONE

@onready var body_visual: AnimatedSprite2D = $BodyVisual
@onready var visual_pivot: Node2D = $VisualPivot
@onready var muzzle: Marker2D = $VisualPivot/Muzzle
@onready var health_component: HealthComponent = $HealthComponent
@onready var team_component: TeamComponent = $TeamComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var weapon_component: WeaponComponent = $WeaponComponent


func _ready() -> void:
	# Ground actor render order is owned by the active arena Y-sort hierarchy.
	z_index = 0
	health_component.died.connect(_on_health_died)
	health_component.health_changed.connect(_on_health_changed)
	hurtbox_component.knockback_requested.connect(_on_knockback_requested)
	weapon_component.fired.connect(_on_weapon_fired)
	_last_health = health_component.current_health
	_body_base_position = body_visual.position
	_body_base_scale = body_visual.scale
	body_visual.play(&"idle")


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	if _is_dead:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
		move_and_slide()
		_update_body_visual(Vector2.ZERO, delta)
		return
	_update_aim()
	if not _input_enabled:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
		move_and_slide()
		_update_body_visual(Vector2.ZERO, delta)
		return
	if Input.is_action_just_pressed("dash"):
		request_dash()
	if _dash_remaining > 0.0:
		velocity = _dash_direction * dash_speed
		move_and_slide()
		_handle_fire()
		_update_body_visual(_dash_direction, delta)
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_velocity := input_dir * move_speed
	velocity = velocity.move_toward(target_velocity, acceleration * delta)
	if input_dir == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	move_and_slide()
	_handle_fire()
	_update_body_visual(input_dir, delta)


func get_aim_direction() -> Vector2:
	var aim := global_position.direction_to(get_global_mouse_position())
	if aim.is_zero_approx():
		return Vector2.RIGHT.rotated(visual_pivot.global_rotation)
	return aim.normalized()


func request_dash() -> void:
	if not _input_enabled or _is_dead or _dash_cooldown_remaining > 0.0 or _dash_remaining > 0.0:
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_dash_direction = input_dir.normalized() if not input_dir.is_zero_approx() else get_aim_direction()
	_dash_remaining = dash_duration
	_dash_cooldown_remaining = dash_cooldown * _dash_cooldown_multiplier
	_invulnerability_remaining = dash_invulnerability
	hurtbox_component.monitorable = false
	body_visual.play(&"dash")
	dash_started.emit()
	dash_cooldown_changed.emit(_dash_cooldown_remaining, dash_cooldown * _dash_cooldown_multiplier)


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not enabled:
		_dash_remaining = 0.0


func get_dash_cooldown_remaining() -> float:
	return _dash_cooldown_remaining


func get_dash_cooldown_maximum() -> float:
	return dash_cooldown * _dash_cooldown_multiplier


func add_max_health(amount: float) -> void:
	if amount <= 0.0:
		return
	health_component.max_health += amount
	health_component.current_health = minf(health_component.current_health + amount, health_component.max_health)
	health_component.health_changed.emit(health_component.current_health, health_component.max_health)


func multiply_weapon_damage(multiplier: float) -> void:
	weapon_component.set_damage_multiplier(weapon_component.damage_multiplier * maxf(multiplier, 0.0))


func multiply_fire_rate(multiplier: float) -> void:
	weapon_component.set_fire_rate_multiplier(weapon_component.fire_rate_multiplier * maxf(multiplier, 0.01))


func multiply_projectile_speed(multiplier: float) -> void:
	weapon_component.set_projectile_speed_multiplier(weapon_component.speed_multiplier * maxf(multiplier, 0.01))


func add_crit_chance(amount: float) -> void:
	weapon_component.set_crit_chance(weapon_component.crit_chance + amount)


func multiply_move_speed(multiplier: float) -> void:
	move_speed *= maxf(multiplier,0.1)


func add_projectile_pierce(amount: int) -> void:
	weapon_component.add_projectile_pierce(amount)


func multiply_dash_recovery(multiplier: float) -> void:
	_dash_cooldown_multiplier = maxf(_dash_cooldown_multiplier * multiplier, 0.1)


func _handle_fire() -> void:
	if _is_dead or not Input.is_action_pressed("fire"):
		return
	weapon_component.try_fire(muzzle.global_position, get_aim_direction(), team_component.team)


func _update_aim() -> void:
	var aim := get_aim_direction()
	if not aim.is_zero_approx():
		visual_pivot.rotation = aim.angle()
		body_visual.flip_h = aim.x < 0.0


func _update_body_visual(input_dir: Vector2, delta: float) -> void:
	_visual_time += delta
	if _is_dead:
		_death_visual_elapsed += delta
		if body_visual.animation != &"death":
			body_visual.play(&"death")
		var death_t := clampf(_death_visual_elapsed / maxf(death_visual_duration, 0.01), 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - death_t, 2.0)
		var fall_direction := -1.0 if body_visual.flip_h else 1.0
		body_visual.position = _body_base_position + Vector2(5.0 * fall_direction * eased, 19.0 * eased)
		body_visual.rotation = fall_direction * 1.02 * eased
		body_visual.scale = Vector2(_body_base_scale.x * (1.0 + 0.05 * eased), _body_base_scale.y * (1.0 - 0.16 * eased))
		var fade := clampf((death_t - 0.72) / 0.28, 0.0, 1.0)
		body_visual.modulate = Color(1.0, 0.88, 0.76, 1.0 - fade * 0.62)
		return

	body_visual.rotation = 0.0
	if _hit_pose_remaining > 0.0:
		if body_visual.animation != &"hit":
			body_visual.play(&"hit")
	elif _dash_remaining > 0.0:
		if body_visual.animation != &"dash":
			body_visual.play(&"dash")
	elif _attack_pose_remaining > 0.0:
		if body_visual.animation != &"attack":
			body_visual.play(&"attack")
	else:
		var next_animation: StringName = &"move" if not input_dir.is_zero_approx() else &"idle"
		if body_visual.animation != next_animation:
			body_visual.play(next_animation)

	if _hit_pose_remaining > 0.0:
		var hit_pulse := 0.5 + 0.5 * sin(_visual_time * 34.0)
		body_visual.position = _body_base_position + Vector2(-3.0 + hit_pulse * 6.0, -1.0)
		body_visual.scale = Vector2(_body_base_scale.x * 1.03, _body_base_scale.y * 0.97)
		body_visual.modulate = Color(1.0, 0.78 + hit_pulse * 0.12, 0.68 + hit_pulse * 0.16, 1.0)
		return
	body_visual.modulate = Color.WHITE

	if _dash_remaining > 0.0:
		var dash_progress := 1.0 - clampf(_dash_remaining / maxf(dash_duration, 0.01), 0.0, 1.0)
		var dash_arch := sin(dash_progress * PI)
		body_visual.position = _body_base_position + Vector2(0.0, -3.0 - dash_arch * 2.0)
		body_visual.scale = Vector2(_body_base_scale.x * (1.15 + dash_arch * 0.09), _body_base_scale.y * (0.88 - dash_arch * 0.04))
		body_visual.rotation = clampf(_dash_direction.y * 0.10, -0.10, 0.10)
		return

	if _attack_pose_remaining > 0.0:
		# Shooting uses authored recoil frames only. Keep the character anchor perfectly
		# stable so repeated shots do not make the whole Prospector twitch on the floor.
		body_visual.position = _body_base_position
		body_visual.scale = _body_base_scale
	elif not input_dir.is_zero_approx():
		# Preserve the run motion the user approved.
		var step := sin(_visual_time * 13.0)
		body_visual.position = _body_base_position + Vector2(0.0, -absf(step) * 2.7)
		body_visual.scale = Vector2(_body_base_scale.x * (1.0 + absf(step) * 0.025), _body_base_scale.y * (1.0 - absf(step) * 0.025))
	else:
		# A true planted idle: no breathing translation or squash/stretch.
		body_visual.position = _body_base_position
		body_visual.scale = _body_base_scale


func _update_timers(delta: float) -> void:
	if _dash_remaining > 0.0:
		_dash_remaining = maxf(_dash_remaining - delta, 0.0)
	if _dash_cooldown_remaining > 0.0:
		_dash_cooldown_remaining = maxf(_dash_cooldown_remaining - delta, 0.0)
		dash_cooldown_changed.emit(_dash_cooldown_remaining, get_dash_cooldown_maximum())
	if _invulnerability_remaining > 0.0:
		_invulnerability_remaining = maxf(_invulnerability_remaining - delta, 0.0)
		if _invulnerability_remaining <= 0.0:
			hurtbox_component.monitorable = true
	if _attack_pose_remaining > 0.0:
		_attack_pose_remaining = maxf(_attack_pose_remaining - delta, 0.0)
	if _hit_pose_remaining > 0.0:
		_hit_pose_remaining = maxf(_hit_pose_remaining - delta, 0.0)


func _on_weapon_fired(_projectile: Node2D) -> void:
	if _is_dead:
		return
	_attack_pose_remaining = attack_pose_hold
	if _dash_remaining <= 0.0:
		body_visual.play(&"attack")


func _on_health_changed(current: float, _maximum: float) -> void:
	if not _is_dead and current < _last_health and current > 0.0:
		_hit_pose_remaining = hit_pose_hold
		body_visual.play(&"hit")
	_last_health = current


func _on_health_died() -> void:
	_is_dead = true
	_death_visual_elapsed = 0.0
	_attack_pose_remaining = 0.0
	_hit_pose_remaining = 0.0
	_dash_remaining = 0.0
	set_input_enabled(false)
	hurtbox_component.monitorable = false
	body_visual.play(&"death")
	player_died.emit()


func _on_knockback_requested(force: Vector2) -> void:
	if not _is_dead and _dash_remaining <= 0.0:
		velocity += force
