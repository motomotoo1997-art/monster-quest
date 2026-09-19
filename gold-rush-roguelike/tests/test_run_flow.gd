extends SceneTree

var _all_arenas_completed := false


func _init() -> void:
	if not _test_enemy_target_fallback():
		return
	if not _test_arena_progression():
		return
	if not _test_boss_phase_transition():
		return
	print("PASS: targeting, arena progression and boss phases")
	quit(0)


func _test_enemy_target_fallback() -> bool:
	var enemy := EnemyBase.new()
	enemy.prefer_core_weight = 1.0
	var player := Node2D.new()
	var core := Node2D.new()
	player.position = Vector2(40, 0)
	core.position = Vector2(100, 0)
	enemy.set_targets(player, core)
	if not _check(enemy.choose_target() == core, "Core-biased enemy must prefer the core"):
		return false
	player.free()
	if not _check(enemy.choose_target() == core, "Enemy must fall back to the surviving core target"):
		return false
	core.free()
	if not _check(enemy.choose_target() == null, "Enemy must return null when no valid target remains"):
		return false
	enemy.free()
	return true


func _test_arena_progression() -> bool:
	var container := Node2D.new()
	container.name = "ArenaContainer"
	root.add_child(container)

	var controller := ArenaController.new()
	controller.name = "ArenaController"
	controller.arena_container_path = NodePath("../ArenaContainer")
	controller.arena_scenes = _make_test_arenas(5)
	if controller.arena_scenes.size() != 5:
		_fail("Could not build five packed arena fixtures")
		return false
	controller.all_arenas_completed.connect(_on_all_arenas_completed)
	root.add_child(controller)

	for expected_index in range(1, 6):
		if not _check(controller.load_arena(expected_index), "Arena %d must load" % expected_index):
			return false
		if not _check(controller.current_arena_index == expected_index,
				"Expected arena index %d, got %d" % [expected_index, controller.current_arena_index]):
			return false
		controller.complete_current_arena()

	if not _check(_all_arenas_completed, "Completing arena 5 must emit all_arenas_completed"):
		return false
	if not _check(not controller.load_next_arena(), "Arena 6 must not load"):
		return false
	if not _check(controller.current_arena_index == 5, "Arena index must remain at 5 after completion"):
		return false
	controller.queue_free()
	container.queue_free()
	return true


func _test_boss_phase_transition() -> bool:
	var scene := load("res://scenes/enemies/GoldBarTank.tscn") as PackedScene
	if not _check(scene != null, "GoldBarTank scene must load"):
		return false
	var boss := scene.instantiate() as GoldBarTank
	if not _check(boss != null, "GoldBarTank scene must instantiate as GoldBarTank"):
		return false
	root.add_child(boss)
	if not _check(boss.phase == 1, "Boss must start in phase one"):
		return false
	if not _check(boss.state >= GoldBarTank.State.INTRO and boss.state <= GoldBarTank.State.DEAD,
			"Boss initial state is outside the state enum"):
		return false
	boss.health_component.damage(500.0)
	if not _check(boss.phase == 2, "Boss must enter phase two below 66% HP"):
		return false
	if not _check(boss.state != GoldBarTank.State.DEAD, "Boss must remain alive in phase two"):
		return false
	boss.health_component.damage(500.0)
	if not _check(boss.phase == 3, "Boss must enter phase three below 33% HP"):
		return false
	if not _check(boss.state >= GoldBarTank.State.INTRO and boss.state <= GoldBarTank.State.DEAD,
			"Boss phase-three state is outside the state enum"):
		return false
	boss.queue_free()
	return true


func _make_test_arenas(count: int) -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []
	for i in range(count):
		var node := Node2D.new()
		node.name = "Arena%d" % (i + 1)
		var packed := PackedScene.new()
		if packed.pack(node) != OK:
			node.free()
			return []
		node.free()
		scenes.append(packed)
	return scenes


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)


func _on_all_arenas_completed() -> void:
	_all_arenas_completed = true
