extends Node
class_name WeaponComponent

signal fired(projectile: Node2D)

@export var projectile_scene: PackedScene
@export_range(0.01, 10.0, 0.01) var cooldown_sec: float = 0.25
@export_range(1.0, 5000.0, 1.0) var projectile_speed: float = 900.0
@export_range(0.0, 100000.0, 0.5) var projectile_damage: float = 12.0
@export_range(0.05, 30.0, 0.05) var projectile_lifetime: float = 2.0

var damage_multiplier: float = 1.0
var fire_rate_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var crit_chance: float = 0.0
var crit_multiplier: float = 2.0
var projectile_pierce: int = 0
var _cooldown_remaining: float = 0.0


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


func can_fire() -> bool:
	return _cooldown_remaining <= 0.0


func mark_fired() -> void:
	_cooldown_remaining = cooldown_sec / maxf(fire_rate_multiplier, 0.01)


func try_fire(
	origin: Vector2,
	direction: Vector2,
	owner_team: TeamComponent.Team
) -> bool:
	if not can_fire() or projectile_scene == null or direction.is_zero_approx():
		return false
	var projectile := projectile_scene.instantiate() as Node2D
	if projectile == null:
		return false
	var target_parent := get_tree().current_scene
	if target_parent == null:
		target_parent = get_parent()
	if target_parent == null:
		projectile.queue_free()
		return false
	target_parent.add_child(projectile)
	projectile.global_position = origin
	var projectile_component := projectile as ProjectileComponent
	if projectile_component == null:
		projectile_component = projectile.get_node_or_null("ProjectileComponent") as ProjectileComponent
	if projectile_component == null:
		projectile.queue_free()
		return false
	var shot_damage := projectile_damage * damage_multiplier
	if crit_chance > 0.0 and randf() < clampf(crit_chance, 0.0, 1.0):
		shot_damage *= crit_multiplier
	projectile_component.lifetime = projectile_lifetime
	projectile_component.configure(
		direction.normalized(),
		projectile_speed * speed_multiplier,
		shot_damage,
		owner_team
	)
	projectile_component.pierce_remaining = projectile_pierce
	mark_fired()
	fired.emit(projectile)
	return true


func set_damage_multiplier(value: float) -> void:
	damage_multiplier = maxf(value, 0.0)


func set_fire_rate_multiplier(value: float) -> void:
	fire_rate_multiplier = maxf(value, 0.01)


func set_projectile_speed_multiplier(value: float) -> void:
	speed_multiplier = maxf(value, 0.01)


func set_crit_chance(value: float) -> void:
	crit_chance = clampf(value, 0.0, 1.0)


func add_projectile_pierce(amount: int) -> void:
	projectile_pierce = maxi(projectile_pierce + amount,0)
