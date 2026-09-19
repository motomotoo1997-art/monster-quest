extends SceneTree

const OUTPUT_PATH := "/tmp/gold-rush-elite-preview.png"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	var main := packed.instantiate() as GoldRushMain
	root.add_child(main)
	current_scene = main
	await process_frame
	main._on_start_requested()
	main.player.set_input_enabled(false)
	main.wave_director.clear_wave()
	if not main.arena_controller.load_arena(4):
		_fail("Arena04 must load for elite preview")
		return
	await process_frame
	await physics_frame

	var scenes: Array[PackedScene] = [main.sentinel_scene, main.slime_scene, main.disc_scene]
	var positions := [Vector2(760,270), Vector2(880,390), Vector2(1030,500)]
	for i in range(scenes.size()):
		var enemy := scenes[i].instantiate() as EnemyBase
		if enemy == null:
			_fail("Elite preview enemy must instantiate")
			return
		main.arena_controller.current_arena.add_child(enemy)
		enemy.global_position = positions[i]
		enemy.apply_elite_modifier()
		enemy.set_targets(main.player, main.core)
		enemy.set_movement_enabled(false)
		if not enemy.is_in_group("elite_enemies"):
			_fail("Preview enemy did not enter elite group")
			return

	for _i in range(24):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Elite preview viewport returned no image")
		return
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		_fail("Could not save elite preview: %s" % error_string(err))
		return
	print("PASS: Arena04 elite readability preview saved to %s (%dx%d)" % [OUTPUT_PATH,image.get_width(),image.get_height()])
	main.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
