extends SceneTree

var _all_arenas_completed := false


func _init() -> void:
	_test_enemy_target_fallback()
	_test_arena_progression()
	quit(0)


func _test_enemy_target_fallback() -> void:
	var enemy := EnemyBase.new()
	enemy.prefer_core_weight = 1.0
	var player := Node2D.new()
	var core := Node2D.new()
	player.position = Vector2(40, 0)
	core.position = Vector2(100, 0)
	enemy.set_targets(player, core)
	assert(enemy.choose_target() == core, "Core-biased enemy must prefer the core")
	player.free()
	assert(enemy.choose_target() == core, "Enemy must fall back to the surviving core target")
	core.free()
	assert(enemy.choose_target() == null, "Enemy must return null when no valid target remains")
	enemy.free()


func _test_arena_progression() -> void:
	var container := Node2D.new()
	container.name = "ArenaContainer"
	root.add_child(container)

	var controller := ArenaController.new()
	controller.name = "ArenaController"
	controller.arena_container_path = NodePath("../ArenaContainer")
	controller.arena_scenes = _make_test_arenas(5)
	controller.all_arenas_completed.connect(_on_all_arenas_completed)
	root.add_child(controller)

	for expected_index in range(1, 6):
		assert(controller.load_arena(expected_index))
		assert(controller.current_arena_index == expected_index)
		controller.complete_current_arena()

	assert(_all_arenas_completed, "Completing arena 5 must emit all_arenas_completed")
	assert(not controller.load_next_arena(), "Arena 6 must not load")
	assert(controller.current_arena_index == 5)
	controller.queue_free()
	container.queue_free()


func _make_test_arenas(count: int) -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []
	for i in range(count):
		var node := Node2D.new()
		node.name = "Arena%d" % (i + 1)
		var packed := PackedScene.new()
		assert(packed.pack(node) == OK)
		node.free()
		scenes.append(packed)
	return scenes


func _on_all_arenas_completed() -> void:
	_all_arenas_completed = true
