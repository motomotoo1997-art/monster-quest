extends SceneTree

var _won := false


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

	main.run_controller.run_won.connect(_on_run_won)
	main.title_overlay.dismiss()
	main.player.set_input_enabled(false)
	main.run_controller.start_new_run()
	main.arena_controller.load_arena(1)
	await process_frame

	for arena_index in range(1, 5):
		if main.arena_controller.current_arena_index != arena_index:
			_fail("Expected arena %d, got %d" % [arena_index, main.arena_controller.current_arena_index])
			return
		for wave_index in range(1, 4):
			main.wave_director.clear_wave()
			main._on_wave_completed(wave_index)
			if wave_index < 3 and main._waiting_for_arena_advance:
				_fail("Arena %d offered reward before wave three" % arena_index)
				return
		if not main._waiting_for_arena_advance:
			_fail("Arena %d must offer a reward after wave three" % arena_index)
			return
		if main.upgrade_overlay.choices.is_empty():
			_fail("Arena %d must present upgrade choices" % arena_index)
			return
		main.upgrade_overlay._select_choice(0)
		await process_frame

	if main.arena_controller.current_arena_index != 5:
		_fail("Completing arena four must advance to boss arena five")
		return
	if main._active_boss == null or not is_instance_valid(main._active_boss):
		_fail("Arena five must spawn Gold Bar Tank")
		return
	await process_frame
	var boss := main._active_boss
	boss.health_component.damage(boss.health_component.max_health + 1.0)
	await process_frame

	if not _won:
		_fail("Destroying Gold Bar Tank with the core alive must emit run_won")
		return
	if main.run_controller.is_run_active or not main.run_controller.is_run_complete:
		_fail("Victory must complete and deactivate the run")
		return

	main.queue_free()
	print("PASS: complete five-arena run reaches Gold Bar Tank victory")
	quit(0)


func _on_run_won() -> void:
	_won = true


func _fail(message: String) -> void:
	get_tree().paused = false
	push_error("FAIL: " + message)
	quit(1)
