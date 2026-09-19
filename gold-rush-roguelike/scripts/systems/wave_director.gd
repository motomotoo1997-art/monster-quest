extends Node
class_name WaveDirector

signal wave_started(number: int)
signal wave_completed(number: int)
signal enemy_spawned(enemy: EnemyBase)

@export var arena_controller_path: NodePath
@export var player_path: NodePath
@export var core_path: NodePath
@export_range(0.0, 80.0, 1.0) var spawn_spread_radius: float = 24.0
@export_range(1, 6, 1) var initial_spawn_burst: int = 3

var current_wave_number: int = 0
var _spawn_queue: Array[Dictionary] = []
var _spawn_timer := 0.0
var _spawning_enabled := false
var _active_enemies: Array[EnemyBase] = []
var _spawn_sequence := 0

var arena_controller: ArenaController
var player: Node2D
var core: Node2D


func _ready() -> void:
	arena_controller = get_node_or_null(arena_controller_path) as ArenaController
	player = get_node_or_null(player_path) as Node2D
	core = get_node_or_null(core_path) as Node2D


func _process(delta: float) -> void:
	_prune_dead_enemies()
	if not _spawning_enabled:
		_check_wave_complete()
		return
	_spawn_timer = maxf(_spawn_timer - delta, 0.0)
	if _spawn_timer <= 0.0:
		_spawn_next()


func start_wave(entries: Array[Dictionary]) -> void:
	_resolve_runtime_dependencies()
	clear_wave()
	current_wave_number += 1
	for entry in entries:
		var count := maxi(int(entry.get("count", 1)), 0)
		for _i in range(count):
			_spawn_queue.append(entry.duplicate())
	_spawning_enabled = not _spawn_queue.is_empty()
	_spawn_timer = 0.30
	wave_started.emit(current_wave_number)
	# arena_started is emitted from inside ArenaController.load_arena(). Defer the opening
	# burst one idle turn so every authored spawn marker has fully entered the SceneTree.
	call_deferred("_spawn_opening_burst")
	if not _spawning_enabled:
		_check_wave_complete()


func _spawn_opening_burst() -> void:
	if not _spawning_enabled or _spawn_queue.is_empty():
		return
	var opening_count := mini(initial_spawn_burst, _spawn_queue.size())
	for _i in range(opening_count):
		_spawn_next()


func stop_spawning() -> void:
	_spawn_queue.clear()
	_spawning_enabled = false


func clear_wave() -> void:
	stop_spawning()
	for enemy in _active_enemies:
		if enemy != null and is_instance_valid(enemy):
			enemy.queue_free()
	_active_enemies.clear()
	_spawn_sequence = 0


func get_alive_enemy_count() -> int:
	_prune_dead_enemies()
	return _active_enemies.size()


func _spawn_next() -> void:
	_resolve_runtime_dependencies()
	if _spawn_queue.is_empty():
		_spawning_enabled = false
		_check_wave_complete()
		return
	var entry: Dictionary = _spawn_queue.pop_front()
	var scene: PackedScene = entry.get("scene") as PackedScene
	_spawn_timer = float(entry.get("interval", 0.4))
	if scene == null or arena_controller == null or arena_controller.current_arena == null:
		return
	var markers: Array[Node2D] = arena_controller.get_markers(&"enemy_spawn")
	if markers.is_empty():
		return
	var enemy := scene.instantiate() as EnemyBase
	if enemy == null:
		return
	arena_controller.current_arena.add_child(enemy)
	enemy.global_position = _get_spawn_position(markers)
	enemy.set_targets(player, core)
	_active_enemies.append(enemy)
	enemy_spawned.emit(enemy)
	_spawn_sequence += 1


func _get_spawn_position(markers: Array[Node2D]) -> Vector2:
	# Rotate deterministically through every arena marker first. When a wave wraps
	# back to a marker, place the next enemy on a compact spiral around that marker
	# instead of stacking multiple sprites/collision bodies at exactly one point.
	var marker_count := markers.size()
	var marker_index := _spawn_sequence % marker_count
	var cycle := int(_spawn_sequence / marker_count)
	var base_position := markers[marker_index].global_position
	if cycle <= 0 or spawn_spread_radius <= 0.0:
		return base_position

	# Golden-angle spacing avoids visible rows while remaining deterministic for
	# tests/replays. Radius grows slowly and is capped so spawn points stay close
	# to their authored arena markers.
	var angle := float(cycle - 1) * 2.39996323 + float(marker_index) * 0.41
	var radius_multiplier := minf(1.0 + float(cycle - 1) * 0.18, 2.0)
	return base_position + Vector2.RIGHT.rotated(angle) * spawn_spread_radius * radius_multiplier


func _resolve_runtime_dependencies() -> void:
	# Be resilient to scene-tree reparenting and SceneTree test launch order.
	# Persistent actors move under the active arena, so their original NodePaths
	# are not guaranteed to remain valid after ArenaController.load_arena().
	if arena_controller == null or not is_instance_valid(arena_controller):
		arena_controller = get_node_or_null(arena_controller_path) as ArenaController
		if arena_controller == null and get_parent() != null:
			arena_controller = get_parent().get_node_or_null("ArenaController") as ArenaController
	if arena_controller == null or arena_controller.current_arena == null:
		return
	if player == null or not is_instance_valid(player):
		player = arena_controller.current_arena.find_child("Prospector", true, false) as Node2D
	if core == null or not is_instance_valid(core):
		core = arena_controller.current_arena.find_child("GoldCore", true, false) as Node2D


func _prune_dead_enemies() -> void:
	var survivors: Array[EnemyBase] = []
	for enemy in _active_enemies:
		if enemy != null and is_instance_valid(enemy) and enemy.is_alive():
			survivors.append(enemy)
	_active_enemies = survivors


func _check_wave_complete() -> void:
	if _spawning_enabled or not _spawn_queue.is_empty() or not _active_enemies.is_empty():
		return
	if current_wave_number <= 0:
		return
	var completed := current_wave_number
	current_wave_number = 0
	wave_completed.emit(completed)
