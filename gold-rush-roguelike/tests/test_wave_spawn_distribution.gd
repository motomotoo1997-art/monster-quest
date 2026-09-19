extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene must load for spawn distribution regression")
		return
	var main := packed.instantiate() as GoldRushMain
	if main == null:
		_fail("Main scene must instantiate for spawn distribution regression")
		return
	root.add_child(main)
	current_scene = main
	await process_frame

	main._on_start_requested()
	await process_frame
	main.wave_director.arena_controller = main.arena_controller
	main.wave_director.player = main.player
	main.wave_director.core = main.core
	main.wave_director.clear_wave()
	await process_frame

	var markers := main.arena_controller.get_markers(&"enemy_spawn")
	if markers.size() < 3:
		_fail("Arena01 must expose at least three spawn markers")
		return

	main.wave_director.start_wave([
		{"scene": main.hopper_scene, "count": 6, "interval": 0.4},
	])
	for _i in range(6):
		main.wave_director._spawn_next()

	var active: Array = main.wave_director.get("_active_enemies") as Array
	if active.size() != 6:
		_fail("Spawn distribution regression needs six active production enemies")
		return

	var unique_positions: Dictionary = {}
	for node in active:
		var enemy := node as EnemyBase
		if enemy == null:
			_fail("WaveDirector active enemy must be EnemyBase")
			return
		var key := Vector2i(roundi(enemy.global_position.x), roundi(enemy.global_position.y))
		unique_positions[key] = true

	if unique_positions.size() != active.size():
		_fail("Rapid WaveDirector spawns must not occupy identical world positions: %d unique for %d enemies" % [unique_positions.size(), active.size()])
		return

	print("PASS: rapid production wave spawns are distributed without exact overlap")
	main.queue_free()
	quit(0)


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
