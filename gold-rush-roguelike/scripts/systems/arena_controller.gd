extends Node
class_name ArenaController

signal arena_will_unload(arena: Node2D)
signal arena_started(index: int)
signal arena_completed(index: int)
signal all_arenas_completed

@export var arena_scenes: Array[PackedScene] = []
@export var arena_container_path: NodePath
@export var persistent_staging_path: NodePath

var current_arena_index: int = 0
var current_arena: Node2D
var _persistent_actors: Array[Node2D] = []
var _persistent_staging: Node2D


func _ready() -> void:
	_persistent_staging = _resolve_persistent_staging()
	_register_staged_persistent_actors()


func load_arena(index: int) -> bool:
	if index < 1 or index > arena_scenes.size():
		return false
	# Refresh at every transition boundary. This makes persistence independent
	# from sibling _ready() order and from optional editor NodePath overrides.
	_register_staged_persistent_actors()
	if current_arena != null and is_instance_valid(current_arena):
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


func _register_staged_persistent_actors() -> void:
	if _persistent_staging == null or not is_instance_valid(_persistent_staging):
		_persistent_staging = _resolve_persistent_staging()
	if _persistent_staging == null:
		return
	for child in _persistent_staging.get_children():
		if child is Node2D:
			var actor := child as Node2D
			if not _persistent_actors.has(actor):
				_persistent_actors.append(actor)


func _stage_persistent_actors() -> void:
	if _persistent_staging == null or not is_instance_valid(_persistent_staging):
		_persistent_staging = _resolve_persistent_staging()
	if _persistent_staging == null:
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


func _resolve_persistent_staging() -> Node2D:
	# Editor-provided path is preferred when valid.
	if not persistent_staging_path.is_empty():
		var configured := get_node_or_null(persistent_staging_path) as Node2D
		if configured != null:
			return configured
	# Main-scene fallback: ArenaController and Actors are siblings. Keeping this
	# lookup here makes scene serialization quirks harmless and is still easy to
	# override for tests or future alternate Main scenes.
	var parent := get_parent()
	if parent != null:
		return parent.get_node_or_null("Actors") as Node2D
	return null


func _get_arena_container() -> Node:
	# Prefer an explicit container when it resolves successfully.
	if not arena_container_path.is_empty():
		var configured := get_node_or_null(arena_container_path)
		if configured != null:
			return configured
	# Main-scene fallback keeps active arenas under ArenaLayer instead of the
	# scene root, which also makes the runtime tree deterministic in tests.
	var parent := get_parent()
	if parent != null:
		var arena_layer := parent.get_node_or_null("ArenaLayer")
		if arena_layer != null:
			return arena_layer
	return parent
