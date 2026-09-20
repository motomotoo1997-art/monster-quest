extends Node
class_name GoldRushMain

@export var hopper_scene: PackedScene
@export var sentinel_scene: PackedScene
@export var disc_scene: PackedScene
@export var slime_scene: PackedScene
@export var boss_scene: PackedScene
@export var hit_flash_scene: PackedScene
@export var explosion_scene: PackedScene
@export var muzzle_flash_scene: PackedScene
@export var dust_burst_scene: PackedScene
@export var enemy_death_burst_scene: PackedScene
@export var boss_death_vfx_scene: PackedScene

@onready var run_controller: RunController = $RunController
@onready var arena_controller: ArenaController = $ArenaController
@onready var wave_director: WaveDirector = $WaveDirector
@onready var arena_event_controller: ArenaEventController = $ArenaEventController
@onready var build_controller: BuildController = $BuildController
@onready var upgrade_controller: UpgradeController = $UpgradeController
@onready var camera_effects: CameraEffectsController = $CameraEffectsController
@onready var hud: GoldRushHUD = $HUD
@onready var title_overlay: TitleOverlay = $TitleOverlay
@onready var pause_overlay: PauseOverlay = $PauseOverlay
@onready var upgrade_overlay: UpgradeOverlay = $UpgradeOverlay
@onready var run_end_overlay: RunEndOverlay = $RunEndOverlay
@onready var player: Prospector = $Actors/Prospector
@onready var core: GoldCore = $Actors/GoldCore

var _waiting_for_arena_advance := false
var _active_boss: GoldBarTank
var _arena_waves: Array = []
var _arena_wave_index := 0


func _ready() -> void:
	run_controller.run_failed.connect(_on_run_failed)
	run_controller.run_won.connect(_on_run_won)
	arena_controller.arena_started.connect(_on_arena_started)
	wave_director.wave_completed.connect(_on_wave_completed)
	wave_director.enemy_spawned.connect(_bind_enemy_feedback)
	build_controller.defense_built.connect(_bind_defense_feedback)
	upgrade_overlay.choice_made.connect(_on_upgrade_chosen)
	title_overlay.start_requested.connect(_on_start_requested)
	player.player_died.connect(func() -> void: run_controller.fail_run("Prospector down"))
	core.core_destroyed.connect(func() -> void: run_controller.fail_run("Gold Core destroyed"))
	player.dash_started.connect(_on_player_dash)
	player.hurtbox_component.hit_received.connect(_on_actor_hit.bind(player))
	var core_hurtbox := core.get_node_or_null("HurtboxComponent") as HurtboxComponent
	if core_hurtbox != null:
		core_hurtbox.hit_received.connect(_on_actor_hit.bind(core))
	player.weapon_component.fired.connect(_on_projectile_fired)
	hud.bind_player(player)
	hud.bind_core(core)
	hud.bind_economy($EconomyController)
	hud.bind_build_controller(build_controller)
	player.set_input_enabled(false)
	pause_overlay.set_pause_enabled(false)


func advance_after_upgrade() -> void:
	if not _waiting_for_arena_advance or not run_controller.is_run_active:
		return
	_waiting_for_arena_advance = false
	arena_controller.load_next_arena()


func _on_start_requested() -> void:
	if run_controller.is_run_active:
		return
	title_overlay.dismiss()
	pause_overlay.set_pause_enabled(true)
	player.set_input_enabled(true)
	_waiting_for_arena_advance = false
	_arena_waves.clear()
	_arena_wave_index = 0
	run_controller.start_new_run()
	arena_controller.load_arena(1)


func _on_arena_started(index: int) -> void:
	arena_event_controller.stop_event()
	_waiting_for_arena_advance = false
	_arena_waves.clear()
	_arena_wave_index = 0
	if index >= 2:
		build_controller.unlock_defense(1)
	if index >= 3:
		build_controller.unlock_defense(3)
	hud.set_arena(index)
	_position_persistent_actors()
	_configure_arena_combat_pacing(index)
	if index == 5:
		_start_boss_encounter()
	else:
		_start_arena_waves(index)


func _configure_arena_combat_pacing(index: int) -> void:
	# Later arenas open with more simultaneous pressure, while a wider deterministic
	# spawn spread keeps silhouettes readable and avoids collision-body stacking.
	match index:
		1, 2:
			wave_director.initial_spawn_burst = 3
			wave_director.spawn_spread_radius = 24.0
		3:
			wave_director.initial_spawn_burst = 4
			wave_director.spawn_spread_radius = 30.0
		4:
			wave_director.initial_spawn_burst = 5
			wave_director.spawn_spread_radius = 36.0
		_:
			wave_director.initial_spawn_burst = 3
			wave_director.spawn_spread_radius = 28.0


func _position_persistent_actors() -> void:
	var player_spawn := arena_controller.get_first_marker(&"player_spawn")
	var core_spawn := arena_controller.get_first_marker(&"core_spawn")
	if player_spawn != null:
		player.global_position = player_spawn.global_position
	if core_spawn != null:
		core.global_position = core_spawn.global_position


func _start_arena_waves(index: int) -> void:
	_arena_waves = _build_arena_waves(index)
	_arena_wave_index = 0
	if _arena_waves.is_empty():
		_finish_arena_after_waves()
		return
	_start_next_arena_wave()


func _build_arena_waves(index: int) -> Array:
	var waves: Array = []
	match index:
		1:
			waves = [
				[
					{"scene": hopper_scene, "count": 6, "interval": 0.34},
					{"scene": sentinel_scene, "count": 2, "interval": 0.52},
					{"scene": disc_scene, "count": 2, "interval": 0.44},
				],
				[
					{"scene": hopper_scene, "count": 8, "interval": 0.34},
					{"scene": sentinel_scene, "count": 2, "interval": 0.58},
				],
				[
					{"scene": hopper_scene, "count": 10, "interval": 0.30},
					{"scene": sentinel_scene, "count": 3, "interval": 0.52},
					{"scene": disc_scene, "count": 2, "interval": 0.46},
				],
			]
		2:
			waves = [
				[
					{"scene": hopper_scene, "count": 8, "interval": 0.55},
					{"scene": sentinel_scene, "count": 3, "interval": 0.85},
				],
				[
					{"scene": hopper_scene, "count": 8, "interval": 0.50},
					{"scene": sentinel_scene, "count": 4, "interval": 0.75},
				],
				[
					{"scene": hopper_scene, "count": 10, "interval": 0.45},
					{"scene": sentinel_scene, "count": 5, "interval": 0.68},
				],
			]
		3:
			waves = [
				[
					{"scene": hopper_scene, "count": 6, "interval": 0.50},
					{"scene": sentinel_scene, "count": 3, "interval": 0.74},
					{"scene": disc_scene, "count": 3, "interval": 0.68},
				],
				[
					{"scene": hopper_scene, "count": 7, "interval": 0.46},
					{"scene": sentinel_scene, "count": 4, "interval": 0.68},
					{"scene": disc_scene, "count": 4, "interval": 0.62},
				],
				[
					{"scene": hopper_scene, "count": 8, "interval": 0.42},
					{"scene": sentinel_scene, "count": 4, "interval": 0.62},
					{"scene": sentinel_scene, "count": 1, "interval": 0.72, "elite": true},
					{"scene": disc_scene, "count": 5, "interval": 0.56},
				],
			]
		4:
			waves = [
				[
					{"scene": slime_scene, "count": 4, "interval": 0.90},
					{"scene": sentinel_scene, "count": 3, "interval": 0.70},
					{"scene": disc_scene, "count": 3, "interval": 0.64},
				],
				[
					{"scene": slime_scene, "count": 4, "interval": 0.84},
					{"scene": slime_scene, "count": 1, "interval": 0.96, "elite": true},
					{"scene": sentinel_scene, "count": 4, "interval": 0.64},
					{"scene": disc_scene, "count": 4, "interval": 0.58},
				],
				[
					{"scene": slime_scene, "count": 6, "interval": 0.72},
					{"scene": slime_scene, "count": 1, "interval": 0.86, "elite": true},
					{"scene": sentinel_scene, "count": 5, "interval": 0.54},
					{"scene": sentinel_scene, "count": 1, "interval": 0.66, "elite": true},
					{"scene": disc_scene, "count": 7, "interval": 0.46},
				],
			]
	return waves


func _start_next_arena_wave() -> void:
	if _arena_wave_index >= _arena_waves.size():
		_finish_arena_after_waves()
		return
	var wave: Array[Dictionary] = []
	var raw_wave: Array = _arena_waves[_arena_wave_index]
	for raw_entry in raw_wave:
		if raw_entry is Dictionary:
			wave.append(raw_entry as Dictionary)
	_arena_wave_index += 1
	hud.set_wave(_arena_wave_index)
	if wave.is_empty():
		_start_next_arena_wave()
		return
	wave_director.start_wave(wave)
	arena_event_controller.start_wave_event(arena_controller.current_arena_index,_arena_wave_index)


func _finish_arena_after_waves() -> void:
	arena_event_controller.stop_event()
	arena_controller.complete_current_arena()
	if arena_controller.current_arena_index >= arena_controller.arena_scenes.size():
		return
	_waiting_for_arena_advance = true
	var choices := upgrade_controller.roll_choices(3)
	if choices.is_empty():
		advance_after_upgrade()
		return
	upgrade_overlay.present(choices)


func _start_boss_encounter() -> void:
	arena_event_controller.stop_event()
	wave_director.clear_wave()
	if boss_scene == null or arena_controller.current_arena == null:
		run_controller.fail_run("Boss scene missing")
		return
	var boss := boss_scene.instantiate() as GoldBarTank
	if boss == null:
		run_controller.fail_run("Boss failed to spawn")
		return
	arena_controller.current_arena.add_child(boss)
	var spawn := arena_controller.get_first_marker(&"boss_spawn")
	boss.global_position = spawn.global_position if spawn != null else Vector2(900, 360)
	boss.set_targets(player, core)
	boss.boss_died.connect(_on_boss_died)
	boss.slam_impact.connect(_on_boss_slam)
	boss.laser_fired.connect(_on_boss_laser)
	_bind_enemy_feedback(boss)
	_active_boss = boss
	hud.show_boss(boss.health_component)


func _on_wave_completed(_number: int) -> void:
	if not run_controller.is_run_active:
		return
	if _arena_wave_index < _arena_waves.size():
		_start_next_arena_wave()
		return
	_finish_arena_after_waves()


func _on_upgrade_chosen(_id: StringName) -> void:
	advance_after_upgrade()


func _on_boss_died() -> void:
	if not run_controller.is_run_active:
		return
	var death_position := Vector2.ZERO
	if _active_boss != null and is_instance_valid(_active_boss):
		death_position = _active_boss.global_position
		_spawn_vfx(boss_death_vfx_scene, death_position)
		camera_effects.shake(16.0, 0.72)
	hud.show_boss(null)
	arena_controller.complete_current_arena()
	if core.is_alive():
		run_controller.win_run()
	else:
		run_controller.fail_run("Gold Core destroyed")


func _bind_enemy_feedback(enemy: EnemyBase) -> void:
	if enemy == null:
		return
	enemy.hurtbox_component.hit_received.connect(_on_actor_hit.bind(enemy))
	if not enemy.enemy_died.is_connected(_on_enemy_died):
		enemy.enemy_died.connect(_on_enemy_died)
	var weapon := enemy.get_node_or_null("WeaponComponent") as WeaponComponent
	if weapon != null:
		weapon.fired.connect(_on_projectile_fired)


func _on_enemy_died(enemy: Node, _gold_value: int) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var enemy_node := enemy as Node2D
	if enemy_node == null:
		return
	_spawn_vfx(enemy_death_burst_scene, enemy_node.global_position)


func _bind_defense_feedback(defense: DefenseBase) -> void:
	if defense == null:
		return
	var weapon := defense.get_node_or_null("WeaponComponent") as WeaponComponent
	if weapon != null:
		weapon.fired.connect(_on_projectile_fired)
	if defense is TNTBarrel:
		(defense as TNTBarrel).exploded.connect(_on_tnt_exploded)


func _on_actor_hit(_damage: float, actor: Node2D) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	_spawn_vfx(hit_flash_scene, actor.global_position)


func _on_projectile_fired(projectile: Node2D) -> void:
	if projectile == null or not is_instance_valid(projectile):
		return
	var vfx := _spawn_vfx(muzzle_flash_scene, projectile.global_position)
	if vfx != null:
		vfx.rotation = projectile.rotation


func _on_player_dash() -> void:
	_spawn_vfx(dust_burst_scene, player.global_position)


func _on_tnt_exploded(world_position: Vector2) -> void:
	_spawn_vfx(explosion_scene, world_position)
	camera_effects.shake(8.0, 0.32)


func _on_boss_slam(world_position: Vector2) -> void:
	_spawn_vfx(explosion_scene, world_position)
	camera_effects.shake(10.0, 0.38)


func _on_boss_laser(origin: Vector2, direction: Vector2) -> void:
	var vfx := _spawn_vfx(muzzle_flash_scene, origin)
	if vfx != null:
		vfx.rotation = direction.angle()
	camera_effects.shake(5.5, 0.18)


func _spawn_vfx(scene: PackedScene, world_position: Vector2) -> Node2D:
	if scene == null:
		return null
	var instance := scene.instantiate() as Node2D
	if instance == null:
		return null
	add_child(instance)
	instance.global_position = world_position
	return instance


func _on_run_failed(reason: String) -> void:
	arena_event_controller.stop_event()
	wave_director.stop_spawning()
	pause_overlay.set_pause_enabled(false)
	player.set_input_enabled(false)
	run_end_overlay.show_failure(reason)


func _on_run_won() -> void:
	arena_event_controller.stop_event()
	wave_director.stop_spawning()
	pause_overlay.set_pause_enabled(false)
	player.set_input_enabled(false)
	run_end_overlay.show_victory()
