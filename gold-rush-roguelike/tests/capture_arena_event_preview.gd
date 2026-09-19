extends SceneTree

const OUTPUT_PATH := "/tmp/gold-rush-arena-event-preview.png"

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
	main.arena_event_controller.stop_event()
	main.arena_controller.load_arena(4)
	await process_frame
	main.wave_director.clear_wave()
	# This is a staged visual QA shot, not a live wave. Prevent WaveDirector from
	# auto-completing the cleared wave and replacing the authored event.
	main.wave_director.current_wave_number = 0
	main.arena_event_controller.start_wave_event(4,3)

	var enemy_scenes: Array[PackedScene] = [main.slime_scene,main.sentinel_scene,main.disc_scene]
	var positions := [Vector2(790,285),Vector2(930,405),Vector2(1080,520)]
	for i in range(enemy_scenes.size()):
		var enemy := enemy_scenes[i].instantiate() as EnemyBase
		main.arena_controller.current_arena.add_child(enemy)
		enemy.global_position = positions[i]
		enemy.set_targets(main.player,main.core)
		enemy.set_movement_enabled(false)
		if i < 2:
			enemy.apply_elite_modifier()

	for _i in range(4):
		await process_frame
	if main.arena_event_controller.get_active_telegraph_count() < 2:
		_fail("Molten burst preview needs multiple live telegraphs")
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Arena event preview viewport returned no image")
		return
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		_fail("Could not save arena event preview: %s" % error_string(err))
		return
	print("PASS: Arena04 molten-event preview saved to %s (%dx%d)" % [OUTPUT_PATH,image.get_width(),image.get_height()])
	main.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
