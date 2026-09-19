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
	main.player.set_input_enabled(false)

	# Capture an actual combat composition instead of an empty opening frame.
	var waited := 0.0
	while root.get_nodes_in_group("enemies").size() < MIN_ENEMIES_FOR_PREVIEW and waited < MAX_WAIT_SECONDS:
		await create_timer(0.25).timeout
		waited += 0.25
	# Let the spawned enemies advance far enough into the central combat lane.
	await create_timer(1.0).timeout
	await process_frame
	await RenderingServer.frame_post_draw

	var enemy_count := root.get_nodes_in_group("enemies").size()
	if enemy_count < MIN_ENEMIES_FOR_PREVIEW:
		_fail("Gameplay preview never reached battle density: %d enemies" % enemy_count)
		return

	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Viewport capture returned no image")
		return
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		_fail("Could not save gameplay preview: %s" % error_string(err))
		return
	print("PASS: gameplay preview saved with %d enemies to %s (%dx%d)" % [enemy_count,OUTPUT_PATH,image.get_width(),image.get_height()])
	main.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
