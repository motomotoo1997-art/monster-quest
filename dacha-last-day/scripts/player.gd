extends CharacterBody2D

signal leveled_up

@export var move_speed: float = 235.0
@export var max_health: int = 100
@export var damage: int = 24
@export var fire_interval: float = 0.28
@export var magazine_size: int = 8
@export var reserve_ammo: int = 56

var health: int
var ammo: int
var level: int = 1
var xp: int = 0
var xp_needed: int = 30
var scrap: int = 40
var fire_clock: float = 0.0
var dash_clock: float = 0.0
var dash_time: float = 0.0
var reloading := false
var reload_key_was_down := false
var dash_key_was_down := false

const BULLET_SCENE := preload("res://scenes/bullet.tscn")

@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var muzzle: Marker2D = $WeaponPivot/Muzzle

func _ready() -> void:
	health = max_health
	ammo = magazine_size

func _physics_process(delta: float) -> void:
	fire_clock = maxf(0.0, fire_clock - delta)
	dash_clock = maxf(0.0, dash_clock - delta)
	dash_time = maxf(0.0, dash_time - delta)

	var input_dir := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	).normalized()

	var dash_down := Input.is_key_pressed(KEY_SHIFT)
	if dash_down and not dash_key_was_down and dash_clock <= 0.0 and input_dir != Vector2.ZERO:
		dash_time = 0.16
		dash_clock = 1.1
	dash_key_was_down = dash_down

	var speed_mult := 2.7 if dash_time > 0.0 else 1.0
	velocity = input_dir * move_speed * speed_mult
	move_and_slide()

	weapon_pivot.look_at(get_global_mouse_position())
	$WeaponPivot/Shotgun.flip_v = absf(weapon_pivot.rotation) > PI * 0.5

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not reloading:
		_try_shoot()

	var reload_down := Input.is_key_pressed(KEY_R)
	if reload_down and not reload_key_was_down and not reloading:
		_reload()
	reload_key_was_down = reload_down

func _try_shoot() -> void:
	if fire_clock > 0.0:
		return
	if ammo <= 0:
		_reload()
		return
	ammo -= 1
	fire_clock = fire_interval
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.rotation = weapon_pivot.rotation
	bullet.damage = damage
	bullet.collision_mask = 2
	get_tree().current_scene.add_child(bullet)
	weapon_pivot.rotation += randf_range(-0.025, 0.025)

func _reload() -> void:
	if ammo >= magazine_size or reserve_ammo <= 0:
		return
	reloading = true
	await get_tree().create_timer(0.72).timeout
	var missing := magazine_size - ammo
	var loaded := mini(missing, reserve_ammo)
	ammo += loaded
	reserve_ammo -= loaded
	reloading = false

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	var tween := create_tween()
	tween.tween_property($Sprite, "modulate", Color(1.0, 0.28, 0.28), 0.06)
	tween.tween_property($Sprite, "modulate", Color.WHITE, 0.12)
	if health <= 0:
		get_tree().reload_current_scene()

func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = 30 + (level - 1) * 22
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
	health = mini(max_health, health + 35)
