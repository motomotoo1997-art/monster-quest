extends SceneTree

const OUTPUT_PATH := "/tmp/gold-rush-gameplay-preview.png"
const MIN_ENEMIES_FOR_PREVIEW := 6
const MAX_SIMULATION_STEPS := 40
const SIMULATION_DELTA := 0.25

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene must load for screenshot capture")
		return
	var main := packed.instantiate() as GoldRushMain
	if main == null:
		_fail("Main scene must instantiate for screenshot capture")
		return
	root.add_child(main)
	await process_frame
	main._on_start_requested()
	paused = false
	main.player.set_input_enabled(false)
	await process_frame

	# A SceneTree launched with --script does not advance Node._process() reliably under xvfb.
	# Drive the real production WaveDirector explicitly so the preview still uses the actual
	# queue, spawn markers, enemy scenes, targeting and enemy_spawned signal path.
	var simulated_steps: int = 0
	while main.wave_director.get_alive_enemy_count() < MIN_ENEMIES_FOR_PREVIEW and simulated_steps < MAX_SIMULATION_STEPS:
		main.wave_director._process(SIMULATION_DELTA)
		await process_frame
		simulated_steps += 1

	# Allow the real enemy scenes and y-sort visuals to settle for several rendered frames.
	for _i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw

	var enemy_count: int = main.wave_director.get_alive_enemy_count()
	if enemy_count < MIN_ENEMIES_FOR_PREVIEW:
		_fail("Gameplay preview never reached battle density: %d enemies (wave %d, steps %d)" % [enemy_count,main.wave_director.current_wave_number,simulated_steps])
		return

	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Viewport capture returned no image")
		return
	var err: Error = image.save_png(OUTPUT_PATH)
	if err != OK:
		_fail("Could not save gameplay preview: %s" % error_string(err))
		return
	print("PASS: gameplay preview saved with %d enemies after %d simulation steps to %s (%dx%d)" % [enemy_count,simulated_steps,OUTPUT_PATH,image.get_width(),image.get_height()])
	main.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
