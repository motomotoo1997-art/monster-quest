extends Node2D

const CHICKEN := preload("res://scenes/enemies/chicken.tscn")
const BOAR := preload("res://scenes/enemies/boar.tscn")
const NEIGHBOR := preload("res://scenes/enemies/neighbor.tscn")
const KING_BOAR := preload("res://scenes/enemies/king_boar.tscn")
const TURRET := preload("res://scenes/td/turret.tscn")
const BRAZIER := preload("res://scenes/td/brazier.tscn")
const FRIDGE := preload("res://scenes/td/fridge.tscn")
const BARRICADE := preload("res://scenes/td/barricade.tscn")

@onready var world: Node2D = $World
@onready var player: CharacterBody2D = $World/Player
@onready var perk_panel: Control = %PerkPanel

var wave := 1
var wave_time := 42.0
var spawn_clock := 0.2
var build_phase := false
var build_time := 0.0
var perk_open := false
var build_key_state: Dictionary = {}
var boss_spawned_wave := 0

func _ready() -> void:
	player.leveled_up.connect(_show_perks)
	%PerkDamage.pressed.connect(_perk_damage)
	%PerkSpeed.pressed.connect(_perk_speed)
	%PerkHeal.pressed.connect(_perk_heal)
	perk_panel.visible = false

func _process(delta: float) -> void:
	_update_atmosphere()
	_update_hud()
	if build_phase:
		build_time -= delta
		_handle_build_input()
		if build_time <= 0.0:
			build_phase = false
			_begin_wave(wave + 1)
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
			_begin_wave(wave + 1)

func _begin_wave(next_wave: int) -> void:
	wave = next_wave
	wave_time = 42.0
	spawn_clock = 0.15
	if wave >= 5 and wave % 5 == 0 and boss_spawned_wave != wave:
		boss_spawned_wave = wave
		_spawn_boss()

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

func _spawn_boss() -> void:
	var boss := KING_BOAR.instantiate()
	boss.global_position = player.global_position + Vector2(680.0, -180.0)
	world.add_child(boss)

func _handle_build_input() -> void:
	if _pressed_once(KEY_T):
		_try_place(TURRET, 20)
	if _pressed_once(KEY_G):
		_try_place(BRAZIER, 18)
	if _pressed_once(KEY_F):
		_try_place(FRIDGE, 22)
	if _pressed_once(KEY_B):
		_try_place(BARRICADE, 10)

func _pressed_once(keycode: Key) -> bool:
	var down := Input.is_key_pressed(keycode)
	var was_down: bool = build_key_state.get(keycode, false)
	build_key_state[keycode] = down
	return down and not was_down

func _try_place(scene: PackedScene, cost: int) -> void:
	if not player.spend_scrap(cost):
		return
	var structure := scene.instantiate()
	structure.global_position = get_global_mouse_position()
	world.add_child(structure)

func _update_atmosphere() -> void:
	if build_phase:
		world.modulate = Color(1.0, 0.9, 0.74, 1.0)
		return
	var progress := clampf(1.0 - wave_time / 42.0, 0.0, 1.0)
	world.modulate = Color.WHITE.lerp(Color(0.58, 0.68, 0.92, 1.0), progress)

func _update_hud() -> void:
	%HealthLabel.text = "Здоровье %d / %d" % [player.health, player.max_health]
	%AmmoLabel.text = "Дробовик %d / %d%s" % [player.ammo, player.reserve_ammo, "  ПЕРЕЗАРЯДКА" if player.reloading else ""]
	%XPLabel.text = "Ур. %d   XP %d / %d   Лом %d" % [player.level, player.xp, player.xp_needed, player.scrap]
	if build_phase:
		%WaveLabel.text = "СТРОЙКА %.0fс  •  T турель  G мангал  F холодильник  B баррикада" % build_time
	else:
		%WaveLabel.text = "Волна %d  •  %.0fс  •  врагов %d" % [wave, wave_time, get_tree().get_nodes_in_group("enemy").size()]
	var bosses := get_tree().get_nodes_in_group("boss")
	%BossLabel.visible = not bosses.is_empty()
	if not bosses.is_empty():
		var boss = bosses[0]
		%BossLabel.text = "ЦАРЬ-КАБАН  %d / %d" % [maxi(0, boss.health), boss.max_health]

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
