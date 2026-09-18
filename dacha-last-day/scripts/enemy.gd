extends CharacterBody2D

@export var max_health: int = 45
@export var speed: float = 105.0
@export var touch_damage: int = 10
@export var attack_distance: float = 46.0
@export var attack_interval: float = 0.9
@export var ranged: bool = false
@export var attack_range: float = 360.0
@export var charge_when_close: bool = false
@export var xp_value: int = 7
@export var scrap_value: int = 2

var health: int
var attack_clock := 0.0
var dead := false
var player: Node2D

const BULLET_SCENE := preload("res://scenes/bullet.tscn")
const XP_SCENE := preload("res://scenes/xp_orb.tscn")

func _ready() -> void:
	health = max_health
	player = get_tree().get_first_node_in_group("player") as Node2D

func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		if not is_instance_valid(player):
			return

	attack_clock = maxf(0.0, attack_clock - delta)
	var target := _current_target()
	if not is_instance_valid(target):
		return
	var dist := global_position.distance_to(target.global_position)

	if ranged and dist <= attack_range:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 6.0 * delta)
		move_and_slide()
		$Sprite.flip_h = target.global_position.x < global_position.x
		if attack_clock <= 0.0:
			_shoot_target(target)
			attack_clock = attack_interval
		return

	if not ranged and dist <= attack_distance:
		velocity = Vector2.ZERO
		if attack_clock <= 0.0 and target.has_method("take_damage"):
			target.take_damage(touch_damage)
			attack_clock = attack_interval
		return

	var chase_speed := speed
	if charge_when_close and dist < 330.0:
		chase_speed *= 2.15
	velocity = global_position.direction_to(target.global_position) * chase_speed
	$Sprite.flip_h = velocity.x < 0.0
	move_and_slide()
	_attack_blocking_structure()

func _current_target() -> Node2D:
	var core := get_tree().get_first_node_in_group("defense_target")
	if core != null and core.active:
		return core as Node2D
	return player

func _attack_blocking_structure() -> void:
	if attack_clock > 0.0:
		return
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider != null and collider.is_in_group("structure") and collider.has_method("take_damage"):
			collider.take_damage(touch_damage)
			attack_clock = attack_interval
			return

func _shoot_target(target: Node2D) -> void:
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = global_position + Vector2(0.0, -28.0)
	bullet.rotation = global_position.direction_to(target.global_position).angle()
	bullet.damage = touch_damage
	bullet.speed = 520.0
	bullet.collision_mask = 32 if target.is_in_group("defense_target") else 1
	get_tree().current_scene.add_child(bullet)

func take_damage(amount: int) -> void:
	if dead:
		return
	health -= amount
	var tween := create_tween()
	tween.tween_property($Sprite, "modulate", Color(1.0, 0.25, 0.2), 0.05)
	tween.tween_property($Sprite, "modulate", Color.WHITE, 0.1)
	if health <= 0:
		_die()

func _die() -> void:
	dead = true
	var orb := XP_SCENE.instantiate()
	orb.global_position = global_position
	orb.value = xp_value
	get_tree().current_scene.add_child(orb)
	if is_instance_valid(player) and player.has_method("add_scrap"):
		player.add_scrap(scrap_value)
	queue_free()
