extends SceneTree

const OUTPUT_PATH := "/tmp/gold-rush-boss-preview.png"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene must load for boss preview")
		return
	var main := packed.instantiate() as GoldRushMain
	if main == null:
		_fail("Main scene must instantiate for boss preview")
		return
	root.add_child(main)
	current_scene = main
	await process_frame

	main._on_start_requested()
	paused = false
	main.player.set_input_enabled(false)
	await process_frame
	await physics_frame

	# Jump to the production boss arena through ArenaController. This intentionally uses
	# Main._on_arena_started(), so the real Gold Bar Tank, HUD binding, spawns and persistent
	# actor positioning are exercised instead of composing a fake presentation scene.
	main.wave_director.clear_wave()
	if not main.arena_controller.load_arena(5):
		_fail("Arena05 must load for boss preview")
		return
	await process_frame
	await physics_frame
	await physics_frame

	var boss := main.get_node_or_null("ArenaContainer/Arena05/GoldBarTank") as GoldBarTank
	if boss == null:
		# The exact generated node path is not part of the gameplay contract, so fall back to
		# the enemies group while still requiring the production GoldBarTank class.
		for node in get_nodes_in_group("enemies"):
			if node is GoldBarTank:
				boss = node as GoldBarTank
				break
	if boss == null:
		_fail("Production Gold Bar Tank did not spawn in Arena05")
		return

	# Build a real unlocked defense through BuildController so the frame represents actual
	# gameplay resources, collision and scene wiring rather than hand-placed showcase art.
	main.build_controller.select_defense(2)
	var built_defense := false
	var build_candidates: Array[Vector2] = [
		Vector2(610, 450),
		Vector2(560, 420),
		Vector2(520, 500),
	]
	for candidate in build_candidates:
		if main.build_controller.confirm_build(candidate):
			built_defense = true
			break
	if not built_defense:
		_fail("Boss preview could not build Cactus through production BuildController")
		return

	# Let foundry atmosphere and defense targeting settle first.
	for _i in range(18):
		await process_frame

	# Put the real boss into the first production attack in its phase-1 pattern. The first
	# pattern entry is CHARGE_TELEGRAPH, so the CI artifact now proves the authored laser
	# warning beam and its dynamic local light instead of capturing a quiet idle frame.
	boss.phase = 1
	boss._attack_index = 0
	boss._choose_next_attack(main.player)
	if boss.state != GoldBarTank.State.CHARGE_TELEGRAPH or not boss.charge_telegraph.visible:
		_fail("Boss preview could not enter the production laser telegraph state")
		return
	for _i in range(8):
		await process_frame
	if boss.charge_light.energy < 1.2:
		_fail("Boss preview telegraph light is not active enough for visual QA")
		return

	# Fire one real player shot immediately before capture so both sides of combat are active.
	var direction := main.player.muzzle.global_position.direction_to(boss.global_position)
	main.player.weapon_component.try_fire(
		main.player.muzzle.global_position,
		direction,
		main.player.team_component.team
	)
	await physics_frame
	for _i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw

	if main.arena_controller.current_arena_index != 5:
		_fail("Boss preview left Arena05 before capture")
		return
	if not boss.is_alive():
		_fail("Gold Bar Tank must remain alive in boss preview")
		return
	if boss.state != GoldBarTank.State.CHARGE_TELEGRAPH:
		_fail("Boss preview must capture the Gold Bar Tank during its laser warning")
		return
	var defenses := get_nodes_in_group("defenses")
	if defenses.is_empty():
		_fail("Boss preview lost its production-built defense")
		return

	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Boss preview viewport returned no image")
		return
	var err: Error = image.save_png(OUTPUT_PATH)
	if err != OK:
		_fail("Could not save boss preview: %s" % error_string(err))
		return
	print("PASS: production Arena05 boss preview saved during laser telegraph with Gold Bar Tank and %d defense(s) to %s (%dx%d)" % [defenses.size(),OUTPUT_PATH,image.get_width(),image.get_height()])
	main.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
