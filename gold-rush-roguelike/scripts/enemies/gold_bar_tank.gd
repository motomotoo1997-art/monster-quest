extends EnemyBase
class_name GoldBarTank

signal boss_phase_changed(phase: int)
signal boss_died
signal slam_impact(world_position: Vector2)
signal laser_fired(origin: Vector2, direction: Vector2)


enum State {
	INTRO,
	CHASE,
	CHARGE_TELEGRAPH,
	CHARGE,
	BURST,
	SLAM,
	SPAWN_ADDS,
	DEAD,
}

@export_range(100.0, 1200.0, 10.0) var laser_range: float = 520.0
@export_range(0.0, 1000.0, 1.0) var laser_damage: float = 42.0
@export_range(0.1, 3.0, 0.05) var charge_telegraph_time: float = 0.75
@export_range(0.05, 1.0, 0.01) var charge_duration: float = 0.20
@export_range(1, 16, 1) var burst_shots: int = 5
@export_range(0.03, 1.0, 0.01) var burst_gap: float = 0.16
@export_range(0.1, 3.0, 0.05) var slam_telegraph_time: float = 0.65
@export_range(0.0, 10000.0, 1.0) var slam_damage: float = 32.0
@export_range(0.0, 1000.0, 1.0) var slam_knockback: float = 270.0
@export_range(0.2, 8.0, 0.05) var base_attack_delay: float = 1.35
@export var add_scenes: Array[PackedScene] = []

var state: State = State.INTRO
var phase: int = 1
var _state_timer := 0.9
var _attack_delay_remaining := 0.0
var _attack_index := 0
var _charge_direction := Vector2.RIGHT
var _laser_has_fired := false
var _burst_remaining := 0
var _burst_timer := 0.0
var _death_announced := false

@onready var weapon_component: WeaponComponent = $WeaponComponent
@onready var muzzle: Marker2D = $Muzzle
@onready var charge_telegraph: Node2D = $ChargeTelegraph
@onready var charge_beam: Polygon2D = $ChargeTelegraph/Beam
@onready var charge_light: PointLight2D = $ChargeTelegraph/ChargeLight
@onready var slam_telegraph: Node2D = $SlamTelegraph
@onready var slam_light: PointLight2D = $SlamTelegraph/SlamLight
@onready var slam_area: Area2D = $SlamArea
@onready var phase_aura: Node2D = $PhaseAura
@onready var phase_light: PointLight2D = $PhaseAura/PhaseLight
@onready var phase_ring: Line2D = $PhaseAura/PhaseRing
@onready var phase_inner_ring: Line2D = $PhaseAura/PhaseInnerRing


func _ready() -> void:
	super()
	add_to_group("boss")
	charge_telegraph.visible = false
	slam_telegraph.visible = false
	phase_aura.visible = false
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_boss_health_died)
	boss_phase_changed.emit(phase)


func _tick_behavior(delta: float) -> void:
	if state == State.DEAD:
		velocity = Vector2.ZERO
		return
	_update_phase_from_health()
	match state:
		State.INTRO:
			velocity = Vector2.ZERO
			_state_timer -= delta
			if _state_timer <= 0.0:
				_enter_chase()
		State.CHASE:
			_tick_chase(delta)
		State.CHARGE_TELEGRAPH:
			_tick_charge_telegraph(delta)
		State.CHARGE:
			_tick_charge(delta)
		State.BURST:
			_tick_burst(delta)
		State.SLAM:
			_tick_slam(delta)
		State.SPAWN_ADDS:
			_tick_spawn_adds(delta)


func _update_visual(delta: float) -> void:
	if visual_sprite == null:
		return
	_visual_time += delta
	var presentation: StringName = &"idle"
	if state == State.CHARGE_TELEGRAPH:
		presentation = &"charge"
	elif state == State.CHARGE or state == State.BURST:
		presentation = &"fire"
	elif phase >= 3:
		presentation = &"damaged"
	if visual_sprite.animation != presentation:
		visual_sprite.play(presentation)
	if absf(velocity.x) > 2.0:
		visual_sprite.flip_h = velocity.x < 0.0

	var phase_tint := Color.WHITE
	if phase == 2:
		phase_tint = Color(1.0, 0.90, 0.70, 1.0)
	elif phase >= 3:
		phase_tint = Color(1.0, 0.72, 0.55, 1.0)

	var aura_pulse := 0.5 + 0.5 * sin(_visual_time * 5.4)
	phase_aura.visible = phase >= 2 and state != State.DEAD
	if phase == 2:
		phase_light.energy = 1.02 + aura_pulse * 0.16
		phase_light.texture_scale = 1.62 + aura_pulse * 0.12
		phase_light.color = Color(0.18, 0.88, 1.0, 1.0)
		phase_ring.default_color = Color(0.18, 0.91, 1.0, 0.72 + aura_pulse * 0.16)
		phase_inner_ring.default_color = Color(1.0, 0.73, 0.14, 0.54 + aura_pulse * 0.14)
	elif phase >= 3:
		phase_light.energy = 1.62 + aura_pulse * 0.32
		phase_light.texture_scale = 1.78 + aura_pulse * 0.16
		phase_light.color = Color(1.0, 0.38, 0.08, 1.0)
		phase_ring.default_color = Color(1.0, 0.34, 0.06, 0.80 + aura_pulse * 0.16)
		phase_inner_ring.default_color = Color(0.22, 0.92, 1.0, 0.62 + aura_pulse * 0.18)
	else:
		phase_light.energy = 0.0
	phase_aura.scale = Vector2.ONE * (0.96 + aura_pulse * 0.07)
	phase_ring.rotation += delta * (0.42 + 0.10 * float(phase))
	phase_inner_ring.rotation -= delta * (0.68 + 0.12 * float(phase))

	var bob := sin(_visual_time * 3.6) * 1.2
	var target_scale := _visual_base_scale
	match state:
		State.CHARGE_TELEGRAPH:
			var pulse := 0.5 + 0.5 * sin(_visual_time * 15.0)
			target_scale = _visual_base_scale * (1.0 + pulse * 0.035)
			charge_beam.color = Color(1.0, 0.26, 0.04, 0.24 + pulse * 0.22)
			charge_light.energy = 1.25 + pulse * 1.15
			charge_light.texture_scale = 0.90 + pulse * 0.18
		State.CHARGE:
			target_scale = Vector2(_visual_base_scale.x * 0.94, _visual_base_scale.y * 1.07)
			charge_beam.color = Color(1.0, 0.58, 0.12, 0.82)
			charge_light.energy = 2.55
			charge_light.texture_scale = 1.12
		State.SLAM:
			var slam_pulse := 0.5 + 0.5 * sin(_visual_time * 12.0)
			target_scale = Vector2(_visual_base_scale.x * (1.0 + slam_pulse * 0.07), _visual_base_scale.y * (1.0 - slam_pulse * 0.05))
			slam_light.energy = 1.05 + slam_pulse * 1.45
			slam_light.texture_scale = 1.35 + slam_pulse * 0.22
		_:
			charge_beam.color = Color(1.0, 0.22, 0.04, 0.26)
			charge_light.energy = 1.0
			slam_light.energy = 0.9
	visual_sprite.position = _visual_base_position + Vector2(0.0, bob)
	visual_sprite.scale = target_scale
	visual_sprite.modulate = phase_tint


func _tick_chase(delta: float) -> void:
	var target := choose_target()
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_attack_delay_remaining = maxf(_attack_delay_remaining - delta, 0.0)
	var distance := global_position.distance_to(target.global_position)
	if distance > 210.0:
		_move_toward(target.global_position, 0.72 + 0.08 * float(phase - 1))
	else:
		var tangent := global_position.direction_to(target.global_position).orthogonal()
		velocity = tangent * move_speed * 0.32 + _get_separation_force()
	move_and_slide()
	if _attack_delay_remaining <= 0.0:
		_choose_next_attack(target)


func _choose_next_attack(target: Node2D) -> void:
	var pattern: Array[State]
	if phase == 1:
		pattern = [State.CHARGE_TELEGRAPH, State.BURST, State.SLAM]
	elif phase == 2:
		pattern = [State.CHARGE_TELEGRAPH, State.BURST, State.SLAM, State.SPAWN_ADDS]
	else:
		pattern = [State.CHARGE_TELEGRAPH, State.SLAM, State.BURST, State.SPAWN_ADDS, State.CHARGE_TELEGRAPH]
	var next_state := pattern[_attack_index % pattern.size()]
	_attack_index += 1
	match next_state:
		State.CHARGE_TELEGRAPH:
			_charge_direction = muzzle.global_position.direction_to(target.global_position)
			_laser_has_fired = false
			_set_state(State.CHARGE_TELEGRAPH, charge_telegraph_time * _phase_time_scale())
			charge_telegraph.rotation = _charge_direction.angle()
			charge_telegraph.visible = true
		State.BURST:
			_burst_remaining = burst_shots + (phase - 1) * 2
			_burst_timer = 0.0
			_set_state(State.BURST, 4.0)
		State.SLAM:
			slam_telegraph.visible = true
			_set_state(State.SLAM, slam_telegraph_time * _phase_time_scale())
		State.SPAWN_ADDS:
			_set_state(State.SPAWN_ADDS, 0.25)


func _tick_charge_telegraph(delta: float) -> void:
	velocity = Vector2.ZERO
	_state_timer -= delta
	if _state_timer <= 0.0:
		_set_state(State.CHARGE, charge_duration)


func _tick_charge(delta: float) -> void:
	velocity = Vector2.ZERO
	if not _laser_has_fired:
		_laser_has_fired = true
		_fire_laser()
	_state_timer -= delta
	if _state_timer <= 0.0:
		charge_telegraph.visible = false
		_enter_chase()


func _fire_laser() -> void:
	var origin := muzzle.global_position
	var end := origin + _charge_direction * laser_range
	var query := PhysicsRayQueryParameters2D.create(origin, end, 2)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.exclude = [hurtbox_component.get_rid()]
	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var hurtbox: HurtboxComponent = hit.get("collider") as HurtboxComponent
		if hurtbox != null and hurtbox.team_component != null and team_component.is_hostile_to(hurtbox.team_component):
			hurtbox.receive_hit(laser_damage, team_component.team, _charge_direction * 180.0)
	laser_fired.emit(origin, _charge_direction)


func _tick_burst(delta: float) -> void:
	velocity = Vector2.ZERO
	var target := choose_target()
	if target == null:
		_enter_chase()
		return
	_burst_timer = maxf(_burst_timer - delta, 0.0)
	if _burst_remaining > 0 and _burst_timer <= 0.0:
		var base_direction := muzzle.global_position.direction_to(target.global_position)
		var spread_step := float(_burst_remaining % 3 - 1) * 0.07
		weapon_component.try_fire(
			muzzle.global_position,
			base_direction.rotated(spread_step),
			team_component.team
		)
		_burst_remaining -= 1
		_burst_timer = burst_gap * _phase_time_scale()
	if _burst_remaining <= 0:
		_enter_chase()


func _tick_slam(delta: float) -> void:
	velocity = Vector2.ZERO
	_state_timer -= delta
	if _state_timer > 0.0:
		return
	slam_telegraph.visible = false
	for area in slam_area.get_overlapping_areas():
		if not area is HurtboxComponent:
			continue
		var hurtbox := area as HurtboxComponent
		if hurtbox.team_component == null or not team_component.is_hostile_to(hurtbox.team_component):
			continue
		var direction := global_position.direction_to(hurtbox.global_position)
		hurtbox.receive_hit(slam_damage, team_component.team, direction * slam_knockback)
	slam_impact.emit(global_position)
	_enter_chase()


func _tick_spawn_adds(delta: float) -> void:
	velocity = Vector2.ZERO
	_state_timer -= delta
	if _state_timer > 0.0:
		return
	_spawn_add_wave()
	_enter_chase()


func _spawn_add_wave() -> void:
	if add_scenes.is_empty() or get_parent() == null:
		return
	var add_count := 1 + phase
	for i in range(add_count):
		var scene := add_scenes[i % add_scenes.size()]
		if scene == null:
			continue
		var add := scene.instantiate() as EnemyBase
		if add == null:
			continue
		get_parent().add_child(add)
		var angle := TAU * float(i) / float(maxi(add_count, 1))
		add.global_position = global_position + Vector2.RIGHT.rotated(angle) * 95.0
		add.set_targets(player_target, core_target)


func _enter_chase() -> void:
	_set_state(State.CHASE, 0.0)
	_attack_delay_remaining = base_attack_delay * _phase_time_scale()


func _set_state(new_state: State, timer: float) -> void:
	state = new_state
	_state_timer = maxf(timer, 0.0)


func _phase_time_scale() -> float:
	match phase:
		2:
			return 0.84
		3:
			return 0.7
		_:
			return 1.0


func _on_health_changed(_current: float, _maximum: float) -> void:
	_update_phase_from_health()


func _update_phase_from_health() -> void:
	if health_component == null or health_component.max_health <= 0.0:
		return
	var ratio := health_component.current_health / health_component.max_health
	var next_phase := 1
	if ratio <= 0.33:
		next_phase = 3
	elif ratio <= 0.66:
		next_phase = 2
	if next_phase != phase:
		phase = next_phase
		boss_phase_changed.emit(phase)


func _on_boss_health_died() -> void:
	if _death_announced:
		return
	_death_announced = true
	state = State.DEAD
	phase_aura.visible = false
	charge_telegraph.visible = false
	slam_telegraph.visible = false
	boss_died.emit()
