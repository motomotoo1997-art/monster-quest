extends CharacterBody2D
class_name EnemyBase

signal enemy_died(enemy: Node, gold_value: int)

@export_range(1.0, 1000.0, 1.0) var move_speed: float = 105.0
@export_range(0.0, 10000.0, 0.5) var contact_damage: float = 9.0
@export_range(1.0, 500.0, 1.0) var attack_range: float = 30.0
@export_range(0.05, 10.0, 0.05) var attack_cooldown: float = 0.85
@export_range(0, 1000, 1) var gold_value: int = 5
@export_range(0.0, 1.0, 0.05) var prefer_core_weight: float = 0.35
@export_range(0.0, 200.0, 1.0) var separation_radius: float = 28.0
@export_range(0.0, 1000.0, 1.0) var separation_strength: float = 130.0

var player_target: Node2D
var core_target: Node2D
var movement_enabled := true
var _attack_cooldown_remaining := 0.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var team_component: TeamComponent = $TeamComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent


func _ready() -> void:
	add_to_group("enemies")
	health_component.died.connect(_on_health_died)
	hurtbox_component.knockback_requested.connect(_on_knockback_requested)


func _physics_process(delta: float) -> void:
	if health_component.is_dead():
		velocity = Vector2.ZERO
		return
	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)
	_tick_behavior(delta)


func set_targets(player: Node2D, core: Node2D) -> void:
	player_target = player
	core_target = core


func choose_target() -> Node2D:
	var player_valid := is_instance_valid(player_target)
	var core_valid := is_instance_valid(core_target)
	if player_valid and not core_valid:
		return player_target
	if core_valid and not player_valid:
		return core_target
	if not player_valid and not core_valid:
		return null
	if prefer_core_weight >= 0.75:
		return core_target
	if prefer_core_weight <= 0.25:
		return player_target
	var player_distance := global_position.distance_squared_to(player_target.global_position)
	var core_distance := global_position.distance_squared_to(core_target.global_position)
	var player_bias := 1.0 + prefer_core_weight
	var core_bias := 2.0 - prefer_core_weight
	return core_target if core_distance * core_bias < player_distance * player_bias else player_target


func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO


func _tick_behavior(_delta: float) -> void:
	var target := choose_target()
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var distance := global_position.distance_to(target.global_position)
	if distance > attack_range:
		_move_toward(target.global_position)
	else:
		velocity = _get_separation_force()
		_try_contact_attack(target)
	move_and_slide()


func _move_toward(world_position: Vector2, speed_multiplier: float = 1.0) -> void:
	if not movement_enabled:
		velocity = Vector2.ZERO
		return
	var desired := global_position.direction_to(world_position) * move_speed * speed_multiplier
	velocity = desired + _get_separation_force()


func _try_contact_attack(target: Node2D) -> bool:
	if _attack_cooldown_remaining > 0.0:
		return false
	var target_hurtbox := target.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if target_hurtbox == null:
		return false
	var knockback := global_position.direction_to(target.global_position) * 90.0
	if not target_hurtbox.receive_hit(contact_damage, team_component.team, knockback):
		return false
	_attack_cooldown_remaining = attack_cooldown
	return true


func _get_separation_force() -> Vector2:
	if separation_radius <= 0.0 or separation_strength <= 0.0:
		return Vector2.ZERO
	var force := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or not other is Node2D:
			continue
		var other_node := other as Node2D
		var offset := global_position - other_node.global_position
		var distance := offset.length()
		if distance <= 0.001 or distance >= separation_radius:
			continue
		force += offset.normalized() * (1.0 - distance / separation_radius) * separation_strength
	return force


func _on_health_died() -> void:
	velocity = Vector2.ZERO
	enemy_died.emit(self, gold_value)
	queue_free()


func _on_knockback_requested(force: Vector2) -> void:
	if movement_enabled:
		velocity += force
