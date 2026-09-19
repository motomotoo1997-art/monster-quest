extends SceneTree

const OUTPUT_PATH := "/tmp/gold-rush-boss-slam-preview.png"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene must load for slam preview")
		return
	var main := packed.instantiate() as GoldRushMain
	root.add_child(main)
	current_scene = main
	await process_frame
	main._on_start_requested()
	paused = false
	main.player.set_input_enabled(false)
	await process_frame
	main.wave_director.clear_wave()
	if not main.arena_controller.load_arena(5):
		_fail("Arena05 must load for slam preview")
		return
	await process_frame
	await physics_frame
	var boss: GoldBarTank
	for node in get_nodes_in_group("enemies"):
		if node is GoldBarTank:
			boss = node as GoldBarTank
			break
	if boss == null:
		_fail("Production Frontier Juggernaut did not spawn")
		return
	boss.phase = 2
	boss._attack_index = 2
	boss._choose_next_attack(main.player)
	boss._update_visual(0.016)
	boss.set_physics_process(false)
	if boss.state != GoldBarTank.State.SLAM or not boss.slam_telegraph.visible:
		_fail("Boss slam telegraph could not be entered through production attack pattern")
		return
	for _i in range(12):
		await process_frame
	if boss.slam_light.energy < 1.0:
		_fail("Slam telegraph light is not readable")
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Boss slam preview viewport returned no image")
		return
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		_fail("Could not save boss slam preview: %s" % error_string(err))
		return
	print("PASS: production boss slam telegraph preview saved to %s (%dx%d)" % [OUTPUT_PATH,image.get_width(),image.get_height()])
	main.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
