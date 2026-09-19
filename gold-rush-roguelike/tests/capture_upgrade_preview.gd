extends SceneTree

const OUTPUT_PATH := "/tmp/gold-rush-upgrade-preview.png"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene must load for upgrade preview")
		return
	var main := packed.instantiate() as GoldRushMain
	root.add_child(main)
	current_scene = main
	await process_frame
	main._on_start_requested()
	paused = false
	main.player.set_input_enabled(false)
	await process_frame
	main.upgrade_controller.set_rng_seed(20260919)
	var choices := main.upgrade_controller.roll_choices(3)
	if choices.size() != 3:
		_fail("Upgrade preview requires three production choices")
		return
	main.upgrade_overlay.present(choices)
	await process_frame
	await RenderingServer.frame_post_draw
	if not paused or not main.upgrade_overlay.panel.visible:
		_fail("Upgrade overlay must be visible and pause gameplay")
		return
	for button in main.upgrade_overlay.buttons:
		if not button.visible or button.text.is_empty():
			_fail("All three upgrade cards must be visible and populated")
			return
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Upgrade preview viewport returned no image")
		return
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		_fail("Could not save upgrade preview: %s" % error_string(err))
		return
	print("PASS: production upgrade overlay preview saved to %s (%dx%d)" % [OUTPUT_PATH,image.get_width(),image.get_height()])
	paused = false
	main.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	paused = false
	quit(1)
