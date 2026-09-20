extends SceneTree

const OUTPUT_PATH := "/tmp/gold-rush-projectile-feedback-preview.png"

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
		_fail("Arena04 must load for projectile feedback preview")
		return
	await process_frame
	await physics_frame

	var projectile_scene := main.player.weapon_component.projectile_scene
	var shots := [
		{"position": Vector2(600,300), "critical": false, "pierce": 0},
		{"position": Vector2(780,390), "critical": false, "pierce": 2},
		{"position": Vector2(960,480), "critical": true, "pierce": 1},
	]
	for shot in shots:
		var projectile := projectile_scene.instantiate() as ProjectileComponent
		if projectile == null:
			_fail("Projectile preview fixture must instantiate")
			return
		main.add_child(projectile)
		projectile.global_position = shot.position
		projectile.configure(Vector2.RIGHT,0.0,24.0,TeamComponent.Team.PLAYER)
		projectile.set_shot_traits(bool(shot.critical),int(shot.pierce))

	for _i in range(20):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Projectile feedback viewport returned no image")
		return
	var err := image.save_png(OUTPUT_PATH)
	if err != OK:
		_fail("Could not save projectile feedback preview: %s" % error_string(err))
		return
	print("PASS: projectile feedback preview saved to %s (%dx%d)" % [OUTPUT_PATH,image.get_width(),image.get_height()])
	main.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
