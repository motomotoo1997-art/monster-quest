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
	print("PASS: arena reward waits for all three combat waves")
	quit(0)


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
