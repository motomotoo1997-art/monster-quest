extends CharacterBody2D

signal leveled_up

@export var move_speed: float = 235.0
@export var max_health: int = 100
@export var damage: int = 24
@export var fire_interval: float = 0.28
@export var magazine_size: int = 8
@export var reserve_ammo: int = 56
@export_file("*.png") var atlas_path := "res://assets/characters/vitya_atlas.png"
@export var atlas_scale := 0.58

var health: int
var ammo: int
var level: int = 1
var xp: int = 0
var xp_needed: int = 30
var scrap: int = 40
var fire_clock := 0.0
var dash_clock := 0.0
var dash_time := 0.0
var reloading := false
var dead := false
var last_aim := Vector2.DOWN
var shot_stream: AudioStream
var level_stream: AudioStream

const BULLET_SCENE := preload("res://scenes/bullet.tscn")
const MUZZLE_FLASH := preload("res://scenes/vfx/muzzle_flash.tscn")
const AtlasAnimator = preload("res://scripts/atlas_animator.gd")

@onready var static_sprite: Sprite2D = $Sprite
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	health = max_health
	ammo = magazine_size
	_configure_visuals()
	if ResourceLoader.exists("res://audio/shotgun.wav"):
		shot_stream = load("res://audio/shotgun.wav") as AudioStream
	if ResourceLoader.exists("res://audio/level_up.wav"):
		level_stream = load("res://audio/level_up.wav") as AudioStream

func _configure_visuals() -> void:
	animated_sprite.visible = false
	if not ResourceLoader.exists(atlas_path):
		return
	var texture := load(atlas_path) as Texture2D
	if texture == null:
		return
	animated_sprite.sprite_frames = AtlasAnimator.build_directional_frames(texture, "move", 8.5)
	animated_sprite.scale = Vector2.ONE * atlas_scale
	animated_sprite.visible = true
	static_sprite.visible = false

func _physics_process(delta: float) -> void:
	if dead:
		return
	fire_clock = maxf(0.0, fire_clock - delta)
	dash_clock = maxf(0.0, dash_clock - delta)
	dash_time = maxf(0.0, dash_time - delta)

	var input_dir := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	).normalized()

	if Input.is_key_pressed(KEY_SHIFT) and dash_clock <= 0.0 and input_dir != Vector2.ZERO:
		dash_time = 0.16
		dash_clock = 1.1

	var speed_mult := 2.7 if dash_time > 0.0 else 1.0
	velocity = input_dir * move_speed * speed_mult
	move_and_slide()

	var aim := get_global_mouse_position() - global_position
	if aim.length_squared() > 4.0:
		last_aim = aim.normalized()
	_update_animation(input_dir)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not reloading:
		_try_shoot(last_aim)
	if Input.is_key_pressed(KEY_R) and not reloading:
		_reload()

func _update_animation(input_dir: Vector2) -> void:
	if not animated_sprite.visible:
		static_sprite.flip_h = last_aim.x < 0.0
		return
	var direction := AtlasAnimator.direction_index(last_aim)
	var animation_name := StringName("move_%d" % direction)
	if input_dir != Vector2.ZERO:
		if animated_sprite.animation != animation_name or not animated_sprite.is_playing():
			animated_sprite.play(animation_name)
	else:
		animated_sprite.animation = animation_name
		animated_sprite.stop()
		animated_sprite.frame = 0

func _try_shoot(aim_direction: Vector2) -> void:
	if fire_clock > 0.0:
		return
	if ammo <= 0:
		_reload()
		return
	ammo -= 1
	fire_clock = fire_interval
	var muzzle_position := global_position + aim_direction * 66.0 + Vector2(0.0, -38.0)
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = muzzle_position
	bullet.rotation = aim_direction.angle()
	bullet.damage = damage
	bullet.collision_mask = 2
	get_tree().current_scene.add_child(bullet)
	var flash := MUZZLE_FLASH.instantiate()
	flash.global_position = muzzle_position
	flash.rotation = aim_direction.angle()
	get_tree().current_scene.add_child(flash)
	_play_sfx(shot_stream, -3.0)
	var visual: Node2D = _visual_node()
	var base_position: Vector2 = visual.position
	var tween := create_tween()
	tween.tween_property(visual, "position", base_position - aim_direction * 4.0, 0.035)
	tween.tween_property(visual, "position", base_position, 0.075)

func _reload() -> void:
	if ammo >= magazine_size or reserve_ammo <= 0 or reloading or dead:
		return
	reloading = true
	await get_tree().create_timer(0.72).timeout
	if dead:
		return
	var missing := magazine_size - ammo
	var loaded := mini(missing, reserve_ammo)
	ammo += loaded
	reserve_ammo -= loaded
	reloading = false

func take_damage(amount: int) -> void:
	if dead:
		return
	health = maxi(0, health - amount)
	var visual: Node2D = _visual_node()
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(1.0, 0.28, 0.28), 0.06)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.12)
	if health <= 0:
		_die()

func _die() -> void:
	dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	var visual: Node2D = _visual_node()
	var tween := create_tween()
	tween.parallel().tween_property(visual, "modulate:a", 0.0, 0.42)
	tween.parallel().tween_property(visual, "rotation", 0.35, 0.42)
	await tween.finished
	get_tree().reload_current_scene()

func heal(amount: int) -> void:
	health = mini(max_health, health + maxi(0, amount))

func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = 30 + (level - 1) * 22
		_play_sfx(level_stream, -5.0)
		leveled_up.emit()

func add_scrap(amount: int) -> void:
	scrap += amount

func spend_scrap(amount: int) -> bool:
	if scrap < amount:
		return false
	scrap -= amount
	return true

func perk_damage() -> void:
	damage = int(round(damage * 1.25))

func perk_speed() -> void:
	move_speed *= 1.15

func perk_heal() -> void:
	heal(35)

func _visual_node() -> Node2D:
	return animated_sprite if animated_sprite.visible else static_sprite

func _play_sfx(stream: AudioStream, volume_db: float) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
