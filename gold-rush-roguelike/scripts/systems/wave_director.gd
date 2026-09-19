extends Node
class_name WaveDirector

signal wave_started(number: int)
signal wave_completed(number: int)
signal enemy_spawned(enemy: EnemyBase)

@export var arena_controller_path: NodePath
@export var player_path: NodePath
@export var core_path: NodePath
@export var gold_pickup_scene: PackedScene

var wave_number: int = 0
var _spawn_queue: Array[Dictionary] = []
var _spawn_timer := 0.0
var _alive_enemies := 0
var _spawning_enabled := false
var _wave_active := false

var arena_controller: ArenaController
var player_target: Node2D
var core_target: Node2D


func _ready() -> void:
	arena_controller = get_node_or_null(arena_controller_path) as ArenaController
	player_target = get_node_or_null(player_path) as Node2D
	core_target = get_node_or_null(core_path) as Node2D


func _process(delta: float) -> void:
	if not _spawning_enabled or _spawn_queue.is_empty():
		_check_wave_complete()
		return
	_spawn_timer = maxf(_spawn_timer - delta, 0.0)
	if _spawn_timer > 0.0:
		return
	_spawn_next()


func start_wave(definition: Array[Dictionary]) -> void:
	stop_spawning()
	_spawn_queue.clear()
	for entry in definition:
		var scene: PackedScene = entry.get("scene") as PackedScene
		var count: int = maxi(int(entry.get("count", 0)), 0)
		var interval: float = maxf(float(entry.get("interval", 0.4)), 0.02)
		if scene == null or count <= 0:
			continue
		for _i in count:
			_spawn_queue.append({"scene": scene, "interval": interval})
	wave_number += 1
	_wave_active = true
	_spawning_enabled = not _spawn_queue.is_empty()
	_spawn_timer = 0.0
	wave_started.emit(wave_number)
	_check_wave_complete()


func stop_spawning() -> void:
	_spawning_enabled = false


func clear_wave() -> void:
	_spawning_enabled = false
	_spawn_queue.clear()
	_wave_active = false


func get_alive_enemy_count() -> int:
	return _alive_enemies


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
	var markers: Array[Node] = arena_controller.get_markers(&"enemy_spawn")
	if markers.is_empty():
		return
	var enemy := scene.instantiate() as EnemyBase
	if enemy == null:
		return
	arena_controller.current_arena.add_child(enemy)
	var marker := markers[randi() % markers.size()] as Node2D
	if marker == null:
		enemy.queue_free()
		return
	enemy.global_position = marker.global_position
	enemy.set_targets(player_target, core_target)
	enemy.enemy_died.connect(_on_enemy_died)
	_alive_enemies += 1
	enemy_spawned.emit(enemy)
	if _spawn_queue.is_empty():
		_spawning_enabled = false


func _on_enemy_died(enemy: Node, gold_value: int) -> void:
	_alive_enemies = maxi(_alive_enemies - 1, 0)
	if enemy is Node2D:
		_spawn_gold((enemy as Node2D).global_position, gold_value)
	_check_wave_complete()


func _spawn_gold(world_position: Vector2, amount: int) -> void:
	if gold_pickup_scene == null or amount <= 0:
		return
	var pickup := gold_pickup_scene.instantiate() as GoldPickup
	if pickup == null:
		return
	var target_parent: Node = arena_controller.current_arena if arena_controller != null else get_tree().current_scene
	if target_parent == null:
		pickup.free()
		return
	target_parent.add_child(pickup)
	pickup.global_position = world_position
	pickup.configure(amount)


func _check_wave_complete() -> void:
	if not _wave_active:
		return
	if _spawning_enabled or not _spawn_queue.is_empty() or _alive_enemies > 0:
		return
	_wave_active = false
	wave_completed.emit(wave_number)
