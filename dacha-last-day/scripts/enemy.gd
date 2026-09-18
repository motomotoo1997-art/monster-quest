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
@export_file("*.png") var atlas_path := ""
@export var atlas_scale := 0.42
@export var visual_tint := Color.WHITE

var health: int
var attack_clock := 0.0
var dead := false
var player: Node2D

const BULLET_SCENE := preload("res://scenes/bullet.tscn")
const XP_SCENE := preload("res://scenes/xp_orb.tscn")
const AtlasAnimator = preload("res://scripts/atlas_animator.gd")

@onready var static_sprite: Sprite2D = $Sprite
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	health = max_health
	player = get_tree().get_first_node_in_group("player") as Node2D
	_configure_visuals()

func _configure_visuals() -> void:
	animated_sprite.visible = false
	static_sprite.modulate = visual_tint
	if atlas_path.is_empty() or not ResourceLoader.exists(atlas_path):
		return
	var texture := load(atlas_path) as Texture2D
	if texture == null:
		return
	animated_sprite.sprite_frames = AtlasAnimator.build_directional_frames(texture, "move", 8.0)
	animated_sprite.scale = Vector2.ONE * atlas_scale
	animated_sprite.modulate = visual_tint
	animated_sprite.visible = true
	static_sprite.visible = false

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
	var target_direction := global_position.direction_to(target.global_position)
	var dist := global_position.distance_to(target.global_position)

	if ranged and dist <= attack_range:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 6.0 * delta)
		move_and_slide()
		_update_visual(target_direction, false)
		if attack_clock <= 0.0:
			_shoot_target(target)
			attack_clock = attack_interval
		return

	if not ranged and dist <= attack_distance:
		velocity = Vector2.ZERO
		_update_visual(target_direction, false)
		if attack_clock <= 0.0 and target.has_method("take_damage"):
			target.take_damage(touch_damage)
			attack_clock = attack_interval
		return

	var chase_speed := speed
	if charge_when_close and dist < 330.0:
		chase_speed *= 2.15
	velocity = target_direction * chase_speed
	move_and_slide()
	_update_visual(target_direction, true)
	_attack_blocking_structure()

func _update_visual(direction: Vector2, moving: bool) -> void:
	if animated_sprite.visible:
		var animation_name := StringName("move_%d" % AtlasAnimator.direction_index(direction))
		if moving:
			if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
				animated_sprite.play(animation_name)
		else:
			animated_sprite.animation = animation_name
			animated_sprite.stop()
			animated_sprite.frame = 0
	else:
		static_sprite.flip_h = direction.x < 0.0

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
	var visual := _visual_node()
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(1.0, 0.25, 0.2), 0.05)
	tween.tween_property(visual, "modulate", visual_tint, 0.1)
	if health <= 0:
		_die()

func _die() -> void:
	dead = true
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	var orb := XP_SCENE.instantiate()
	orb.global_position = global_position
	orb.value = xp_value
	get_tree().current_scene.add_child(orb)
	if is_instance_valid(player) and player.has_method("add_scrap"):
		player.add_scrap(scrap_value)
	var visual := _visual_node()
	var tween := create_tween()
	tween.parallel().tween_property(visual, "modulate:a", 0.0, 0.18)
	tween.parallel().tween_property(visual, "scale", visual.scale * 0.82, 0.18)
	await tween.finished
	queue_free()

func _visual_node() -> CanvasItem:
	return animated_sprite if animated_sprite.visible else static_sprite
