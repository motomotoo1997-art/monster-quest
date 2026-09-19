extends Node
class_name ArenaController

signal arena_will_unload(arena: Node2D)
signal arena_started(index: int)
signal arena_completed(index: int)
signal all_arenas_completed

@export var arena_scenes: Array[PackedScene] = []
@export var arena_container_path: NodePath
@export var persistent_staging_path: NodePath
@export var player_actor_path: NodePath
@export var core_actor_path: NodePath

var current_arena_index: int = 0
var current_arena: Node2D
var _persistent_actors: Array[Node2D] = []
var _persistent_staging: Node2D


func _ready() -> void:
	_persistent_staging = get_node_or_null(persistent_staging_path) as Node2D
	_register_persistent_actor(player_actor_path)
	_register_persistent_actor(core_actor_path)


func load_arena(index: int) -> bool:
	if index < 1 or index > arena_scenes.size():
		return false
	if current_arena != null and is_instance_valid(current_arena):
		# Pull persistent actors out before destroying the old arena. This keeps
		# references stable while still allowing actors to live inside the active
		# arena's single Y-sort hierarchy during gameplay.
		_stage_persistent_actors()
		arena_will_unload.emit(current_arena)
		current_arena.queue_free()
		current_arena = null
	var scene := arena_scenes[index - 1]
	if scene == null:
		return false
	var instance := scene.instantiate() as Node2D
	if instance == null:
		return false
	var container := _get_arena_container()
	if container == null:
		instance.free()
		return false
	container.add_child(instance)
	current_arena = instance
	current_arena_index = index
	_attach_persistent_actors(instance)
	arena_started.emit(index)
	return true


func complete_current_arena() -> void:
	if current_arena_index <= 0:
		return
	arena_completed.emit(current_arena_index)
	if current_arena_index >= arena_scenes.size():
		all_arenas_completed.emit()


func load_next_arena() -> bool:
	var next_index := current_arena_index + 1
	if next_index > arena_scenes.size():
		all_arenas_completed.emit()
		return false
	return load_arena(next_index)


func get_markers(group_name: StringName) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if current_arena == null:
		return result
	for node in get_tree().get_nodes_in_group(group_name):
		if node is Node2D and current_arena.is_ancestor_of(node):
			result.append(node as Node2D)
	return result


func get_first_marker(group_name: StringName) -> Node2D:
	var markers := get_markers(group_name)
	return markers[0] if not markers.is_empty() else null


func _register_persistent_actor(actor_path: NodePath) -> void:
	if actor_path.is_empty():
		return
	var actor := get_node_or_null(actor_path) as Node2D
	if actor != null and not _persistent_actors.has(actor):
		_persistent_actors.append(actor)


func _stage_persistent_actors() -> void:
	if _persistent_staging == null or not is_instance_valid(_persistent_staging):
		return
	for actor in _persistent_actors:
		if actor != null and is_instance_valid(actor) and actor.get_parent() != _persistent_staging:
			actor.reparent(_persistent_staging, true)


func _attach_persistent_actors(arena: Node2D) -> void:
	if arena == null:
		return
	for actor in _persistent_actors:
		if actor != null and is_instance_valid(actor) and actor.get_parent() != arena:
			actor.reparent(arena, true)


func _get_arena_container() -> Node:
	if not arena_container_path.is_empty():
		return get_node_or_null(arena_container_path)
	return get_parent()
