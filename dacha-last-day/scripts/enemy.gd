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
var player: CharacterBody2D

const BULLET_SCENE := preload("res://scenes/bullet.tscn")
const XP_SCENE := preload("res://scenes/xp_orb.tscn")

func _ready() -> void:
	health = max_health
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		return
	attack_clock = maxf(0.0, attack_clock - delta)
	var dist := global_position.distance_to(player.global_position)

	if ranged and dist <= attack_range:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 6.0 * delta)
		move_and_slide()
		$Sprite.flip_h = player.global_position.x < global_position.x
		if attack_clock <= 0.0:
			_shoot_player()
			attack_clock = attack_interval
		return

	if not ranged and dist <= attack_distance:
		velocity = Vector2.ZERO
		if attack_clock <= 0.0:
			player.take_damage(touch_damage)
			attack_clock = attack_interval
		return

	var chase_speed := speed
	if charge_when_close and dist < 330.0:
		chase_speed *= 2.15
	velocity = global_position.direction_to(player.global_position) * chase_speed
	$Sprite.flip_h = velocity.x < 0.0
	move_and_slide()

func _shoot_player() -> void:
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = global_position + Vector2(0.0, -28.0)
	bullet.rotation = global_position.direction_to(player.global_position).angle()
	bullet.damage = touch_damage
	bullet.speed = 520.0
	bullet.collision_mask = 1
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
	if is_instance_valid(player):
		player.add_scrap(scrap_value)
	queue_free()
