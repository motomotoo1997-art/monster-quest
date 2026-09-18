extends Node2D

const CHICKEN := preload("res://scenes/enemies/chicken.tscn")
const BOAR := preload("res://scenes/enemies/boar.tscn")
const NEIGHBOR := preload("res://scenes/enemies/neighbor.tscn")
const TURRET := preload("res://scenes/td/turret.tscn")

@onready var world: Node2D = $World
@onready var player: CharacterBody2D = $World/Player
@onready var perk_panel: Control = %PerkPanel

var wave := 1
var wave_time := 42.0
var spawn_clock := 0.2
var build_phase := false
var build_time := 0.0
var turret_key_was_down := false
var perk_open := false

func _ready() -> void:
	player.leveled_up.connect(_show_perks)
	%PerkDamage.pressed.connect(_perk_damage)
	%PerkSpeed.pressed.connect(_perk_speed)
	%PerkHeal.pressed.connect(_perk_heal)
	perk_panel.visible = false

func _process(delta: float) -> void:
	_update_hud()
	if build_phase:
		build_time -= delta
		_handle_build_input()
		if build_time <= 0.0:
			build_phase = false
			wave += 1
			wave_time = 42.0
		return

	wave_time -= delta
	spawn_clock -= delta
	if spawn_clock <= 0.0:
		_spawn_enemy()
		spawn_clock = maxf(0.34, 1.25 - wave * 0.055)
	if wave_time <= 0.0:
		if wave % 3 == 0:
			build_phase = true
			build_time = 12.0
		else:
			wave += 1
			wave_time = 42.0

func _spawn_enemy() -> void:
	var scene: PackedScene = CHICKEN
	var roll := randf()
	if wave >= 2 and roll > 0.62:
		scene = BOAR
	if wave >= 3 and roll > 0.82:
		scene = NEIGHBOR
	var enemy := scene.instantiate()
	var angle := randf() * TAU
	var radius := randf_range(520.0, 760.0)
	enemy.global_position = player.global_position + Vector2.RIGHT.rotated(angle) * radius
	world.add_child(enemy)

func _handle_build_input() -> void:
	var down := Input.is_key_pressed(KEY_T)
	if down and not turret_key_was_down and player.spend_scrap(20):
		var turret := TURRET.instantiate()
		turret.global_position = get_global_mouse_position()
		world.add_child(turret)
	turret_key_was_down = down

func _update_hud() -> void:
	%HealthLabel.text = "Здоровье %d / %d" % [player.health, player.max_health]
	%AmmoLabel.text = "Дробовик %d / %d%s" % [player.ammo, player.reserve_ammo, "  ПЕРЕЗАРЯДКА" if player.reloading else ""]
	%XPLabel.text = "Ур. %d   XP %d / %d   Лом %d" % [player.level, player.xp, player.xp_needed, player.scrap]
	%WaveLabel.text = "СТРОЙКА %.0fс  •  T = турель (20 лома)" % build_time if build_phase else "Волна %d  •  %.0fс  •  врагов %d" % [wave, wave_time, get_tree().get_nodes_in_group("enemy").size()]

func _show_perks() -> void:
	perk_open = true
	perk_panel.visible = true

func _hide_perks() -> void:
	perk_open = false
	perk_panel.visible = false

func _perk_damage() -> void:
	player.perk_damage()
	_hide_perks()

func _perk_speed() -> void:
	player.perk_speed()
	_hide_perks()

func _perk_heal() -> void:
	player.perk_heal()
	_hide_perks()
