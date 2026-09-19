extends Node
class_name WaveDirector

signal wave_started(number: int)
signal wave_completed(number: int)
signal enemy_spawned(enemy: EnemyBase)

@export var arena_controller_path: NodePath
@export var player_path: NodePath
@export var core_path: NodePath

var current_wave_number: int = 0
var _spawn_queue: Array[Dictionary] = []
var _spawn_timer := 0.0
var _spawning_enabled := false
var _active_enemies: Array[EnemyBase] = []

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
	clear_wave()
	current_wave_number += 1
	for entry in entries:
		var count := maxi(int(entry.get("count", 1)), 0)
		for _i in range(count):
			_spawn_queue.append(entry.duplicate())
	_spawning_enabled = not _spawn_queue.is_empty()
	_spawn_timer = 0.05
	wave_started.emit(current_wave_number)
	if not _spawning_enabled:
		_check_wave_complete()


func stop_spawning() -> void:
	_spawn_queue.clear()
	_spawning_enabled = false


func clear_wave() -> void:
	stop_spawning()
	for enemy in _active_enemies:
		if enemy != null and is_instance_valid(enemy):
			enemy.queue_free()
	_active_enemies.clear()


func get_alive_enemy_count() -> int:
	_prune_dead_enemies()
	return _active_enemies.size()


func _spawn_next() -> void:
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
	var marker: Node2D = markers[randi() % markers.size()]
	var enemy := scene.instantiate() as EnemyBase
	if enemy == null:
		return
	arena_controller.current_arena.add_child(enemy)
	enemy.global_position = marker.global_position
	enemy.set_targets(player, core)
	_active_enemies.append(enemy)
	enemy_spawned.emit(enemy)


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
