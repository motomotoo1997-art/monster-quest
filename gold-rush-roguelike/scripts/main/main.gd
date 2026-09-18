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

@onready var run_controller: RunController = $RunController
@onready var arena_controller: ArenaController = $ArenaController
@onready var wave_director: WaveDirector = $WaveDirector
@onready var build_controller: BuildController = $BuildController
@onready var upgrade_controller: UpgradeController = $UpgradeController
@onready var camera_effects: CameraEffectsController = $CameraEffectsController
@onready var hud: GoldRushHUD = $HUD
@onready var upgrade_overlay: UpgradeOverlay = $UpgradeOverlay
@onready var run_end_overlay: RunEndOverlay = $RunEndOverlay
@onready var player: Prospector = $Actors/Prospector
@onready var core: GoldCore = $Actors/GoldCore

var _waiting_for_arena_advance := false
var _active_boss: GoldBarTank


func _ready() -> void:
	run_controller.run_failed.connect(_on_run_failed)
	run_controller.run_won.connect(_on_run_won)
	arena_controller.arena_started.connect(_on_arena_started)
	wave_director.wave_started.connect(hud.set_wave)
	wave_director.wave_completed.connect(_on_wave_completed)
	wave_director.enemy_spawned.connect(_bind_enemy_feedback)
	build_controller.defense_built.connect(_bind_defense_feedback)
	upgrade_overlay.choice_made.connect(_on_upgrade_chosen)
	player.player_died.connect(func() -> void: run_controller.fail_run("Prospector down"))
	core.core_destroyed.connect(func() -> void: run_controller.fail_run("Gold Core destroyed"))
	player.dash_started.connect(_on_player_dash)
	player.hurtbox_component.hit_received.connect(_on_actor_hit.bind(player))
	core.get_node("HurtboxComponent").hit_received.connect(_on_actor_hit.bind(core))
	player.weapon_component.fired.connect(_on_projectile_fired)
	hud.bind_player(player)
	hud.bind_core(core)
	hud.bind_economy($EconomyController)
	hud.bind_build_controller(build_controller)
	run_controller.start_new_run()
	arena_controller.load_arena(1)


func advance_after_upgrade() -> void:
	if not _waiting_for_arena_advance or not run_controller.is_run_active:
		return
	_waiting_for_arena_advance = false
	arena_controller.load_next_arena()


func _on_arena_started(index: int) -> void:
	if index >= 2:
		build_controller.unlock_defense(1)
	if index >= 3:
		build_controller.unlock_defense(3)
	hud.set_arena(index)
	_position_persistent_actors()
	if index == 5:
		_start_boss_encounter()
	else:
		_start_arena_wave(index)


func _position_persistent_actors() -> void:
	var player_spawn := arena_controller.get_first_marker(&"player_spawn")
	var core_spawn := arena_controller.get_first_marker(&"core_spawn")
	if player_spawn != null:
		player.global_position = player_spawn.global_position
	if core_spawn != null:
		core.global_position = core_spawn.global_position


func _start_arena_wave(index: int) -> void:
	var wave: Array[Dictionary] = []
	match index:
		1:
			wave = [{"scene": hopper_scene, "count": 8, "interval": 0.55}]
		2:
			wave = [
				{"scene": hopper_scene, "count": 8, "interval": 0.45},
				{"scene": sentinel_scene, "count": 3, "interval": 0.75},
			]
		3:
			wave = [
				{"scene": hopper_scene, "count": 7, "interval": 0.38},
				{"scene": sentinel_scene, "count": 4, "interval": 0.62},
				{"scene": disc_scene, "count": 4, "interval": 0.55},
			]
		4:
			wave = [
				{"scene": slime_scene, "count": 5, "interval": 0.85},
				{"scene": sentinel_scene, "count": 4, "interval": 0.55},
				{"scene": disc_scene, "count": 5, "interval": 0.5},
			]
	if wave.is_empty():
		arena_controller.complete_current_arena()
		return
	wave_director.start_wave(wave)


func _start_boss_encounter() -> void:
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
	_bind_enemy_feedback(boss)
	_active_boss = boss
	hud.show_boss(boss.health_component)


func _on_wave_completed(_number: int) -> void:
	if not run_controller.is_run_active:
		return
	arena_controller.complete_current_arena()
	if arena_controller.current_arena_index >= arena_controller.arena_scenes.size():
		return
	_waiting_for_arena_advance = true
	var choices := upgrade_controller.roll_choices(3)
	if choices.is_empty():
		advance_after_upgrade()
		return
	upgrade_overlay.present(choices)


func _on_upgrade_chosen(_id: StringName) -> void:
	advance_after_upgrade()


func _on_boss_died() -> void:
	if not run_controller.is_run_active:
		return
	hud.show_boss(null)
	arena_controller.complete_current_arena()
	if core.is_alive():
		run_controller.win_run()
	else:
		run_controller.fail_run("Gold Core destroyed")


func _bind_enemy_feedback(enemy: EnemyBase) -> void:
	if enemy == null:
		return
	if not enemy.hurtbox_component.hit_received.is_connected(_on_actor_hit.bind(enemy)):
		enemy.hurtbox_component.hit_received.connect(_on_actor_hit.bind(enemy))
	var weapon := enemy.get_node_or_null("WeaponComponent") as WeaponComponent
	if weapon != null:
		weapon.fired.connect(_on_projectile_fired)


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
	wave_director.stop_spawning()
	player.set_input_enabled(false)
	run_end_overlay.show_failure(reason)


func _on_run_won() -> void:
	wave_director.stop_spawning()
	player.set_input_enabled(false)
	run_end_overlay.show_victory()
