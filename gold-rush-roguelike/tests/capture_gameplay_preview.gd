extends SceneTree

const OUTPUT_PATH := "/tmp/gold-rush-gameplay-preview.png"

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
	main.title_overlay.dismiss()
	main._on_title_start_requested()
	main.player.set_input_enabled(false)
	# Let Arena01 load and enough of wave one spawn to prove enemy readability.
	await create_timer(2.2).timeout
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Viewport capture returned no image")
		return
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		_fail("Could not save gameplay preview: %s" % error_string(err))
		return
	print("PASS: gameplay preview saved to %s (%dx%d)" % [OUTPUT_PATH,image.get_width(),image.get_height()])
	main.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
