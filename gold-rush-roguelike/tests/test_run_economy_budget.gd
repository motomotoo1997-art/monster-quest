extends SceneTree

const MIN_RUN_GOLD := 550
const MAX_RUN_GOLD := 750


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var main_scene := load("res://scenes/main/Main.tscn") as PackedScene
	if main_scene == null:
		_fail("Main scene must load")
		return
	var main := main_scene.instantiate() as GoldRushMain
	if main == null:
		_fail("Main scene must instantiate")
		return
	root.add_child(main)
	await process_frame

	var economy := main.get_node("EconomyController") as EconomyController
	if economy == null:
		_fail("EconomyController must exist")
		return
	var cheapest_defense := mini(
		main.build_controller.get_defense_cost(0),
		mini(main.build_controller.get_defense_cost(1), main.build_controller.get_defense_cost(3))
	)
	if economy.starting_gold < cheapest_defense:
		_fail("Starting gold must afford at least one defense")
		return

	var total_gold := economy.starting_gold
	for arena_index in range(1, 5):
		var waves: Array = main._build_arena_waves(arena_index)
		if waves.size() != 3:
			_fail("Arena %d must define exactly three combat waves" % arena_index)
			return
		for raw_wave in waves:
			for raw_entry in raw_wave:
				var entry := raw_entry as Dictionary
				var scene := entry.get("scene") as PackedScene
				var count := int(entry.get("count", 0))
				if scene == null or count <= 0:
					_fail("Arena %d contains an invalid wave entry" % arena_index)
					return
				var enemy := scene.instantiate() as EnemyBase
				if enemy == null:
					_fail("Wave enemy must instantiate as EnemyBase")
					return
				total_gold += enemy.gold_value * count
				enemy.free()

	if total_gold < MIN_RUN_GOLD or total_gold > MAX_RUN_GOLD:
		_fail("Full-run gold budget %d must stay within %d..%d" % [total_gold, MIN_RUN_GOLD, MAX_RUN_GOLD])
		return

	main.queue_free()
	print("PASS: full-run economy budget = %d gold" % total_gold)
	quit(0)


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
