extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var scene := load("res://scenes/main/Main.tscn") as PackedScene
	if scene == null:
		_fail("Main scene must load")
		return
	var main := scene.instantiate() as GoldRushMain
	if main == null:
		_fail("Main scene must instantiate as GoldRushMain")
		return
	root.add_child(main)
	await process_frame

	if not main.has_method("_configure_arena_combat_pacing"):
		_fail("Late arenas need an explicit combat pacing profile")
		return
	main.call("_configure_arena_combat_pacing",3)
	if main.wave_director.initial_spawn_burst < 4 or main.wave_director.spawn_spread_radius < 30.0:
		_fail("Arena 3 must open with a denser but spatially readable spawn profile")
		return
	main.call("_configure_arena_combat_pacing",4)
	if main.wave_director.initial_spawn_burst < 5 or main.wave_director.spawn_spread_radius < 34.0:
		_fail("Arena 4 must escalate opening pressure without stacking enemies")
		return

	var arena3_waves: Array = main._build_arena_waves(3)
	var arena4_waves: Array = main._build_arena_waves(4)
	if arena3_waves.size() != 3 or arena4_waves.size() != 3:
		_fail("Arena 3 and 4 must keep the three-wave reward cadence")
		return
	if _count_entries(arena3_waves[2]) < 18:
		_fail("Arena 3 final wave must sustain at least 18 enemies of mixed archetypes")
		return
	if _count_entries(arena4_waves[2]) < 20:
		_fail("Arena 4 final wave must sustain at least 20 enemies including elites")
		return

	main.title_overlay.dismiss()
	main.run_controller.start_new_run()
	main.arena_controller.load_arena(1)
	await process_frame

	for completed_wave in range(1, 3):
		main.wave_director.clear_wave()
		main._on_wave_completed(completed_wave)
		if main._waiting_for_arena_advance:
			_fail("Arena 1 must not offer upgrade after wave %d" % completed_wave)
			return

	main.wave_director.clear_wave()
	main._on_wave_completed(3)
	if not main._waiting_for_arena_advance:
		_fail("Arena 1 must offer upgrade after the third wave")
		return

	main.queue_free()
	print("PASS: arena reward cadence and late-run combat density are both preserved")
	quit(0)


func _count_entries(raw_wave: Variant) -> int:
	if not raw_wave is Array:
		return 0
	var total := 0
	for entry in raw_wave as Array:
		if entry is Dictionary:
			total += maxi(int((entry as Dictionary).get("count",0)),0)
	return total


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
