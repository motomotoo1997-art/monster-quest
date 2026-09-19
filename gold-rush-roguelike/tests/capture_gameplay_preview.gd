extends SceneTree

const OUTPUT_PATH := "/tmp/gold-rush-gameplay-preview.png"
const MIN_ENEMIES_FOR_PREVIEW := 6
const MAX_WAIT_SECONDS := 8.0

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
	# --script preview runs outside the normal launcher, so explicitly keep the tree live
	# after dismissing the title overlay. The WaveDirector itself remains production code.
	paused = false
	main.player.set_input_enabled(false)
	await process_frame

	var waited: float = 0.0
	while main.wave_director.get_alive_enemy_count() < MIN_ENEMIES_FOR_PREVIEW and waited < MAX_WAIT_SECONDS:
		await create_timer(0.25, true).timeout
		waited += 0.25
	await create_timer(1.0, true).timeout
	await process_frame
	await RenderingServer.frame_post_draw

	var enemy_count: int = main.wave_director.get_alive_enemy_count()
	if enemy_count < MIN_ENEMIES_FOR_PREVIEW:
		_fail("Gameplay preview never reached battle density: %d enemies (wave %d)" % [enemy_count,main.wave_director.current_wave_number])
		return

	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Viewport capture returned no image")
		return
	var err: Error = image.save_png(OUTPUT_PATH)
	if err != OK:
		_fail("Could not save gameplay preview: %s" % error_string(err))
		return
	print("PASS: gameplay preview saved with %d enemies to %s (%dx%d)" % [enemy_count,OUTPUT_PATH,image.get_width(),image.get_height()])
	main.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
