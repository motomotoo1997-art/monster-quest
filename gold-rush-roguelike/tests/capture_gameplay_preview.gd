extends SceneTree

const OUTPUT_PATH := "/tmp/gold-rush-gameplay-preview.png"
const MIN_ENEMIES_FOR_PREVIEW := 9
const TARGET_ENEMIES_FOR_PREVIEW := 10
const MAX_SPAWN_ATTEMPTS := 14

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
	current_scene = main
	await process_frame
	main._on_start_requested()
	paused = false
	main.player.set_input_enabled(false)
	await process_frame
	await physics_frame
	await physics_frame

	# Build the starting Cactus through the real production build/economy path. Prefer a
	# forward position so it genuinely engages the incoming wave and emits production VFX.
	main.build_controller.select_defense(2)
	var built_defense := false
	var build_candidates: Array[Vector2] = [
		Vector2(900, 430),
		Vector2(870, 400),
		Vector2(645, 505),
	]
	for candidate in build_candidates:
		if main.build_controller.confirm_build(candidate):
			built_defense = true
			break
	if not built_defense:
		_fail("Gameplay preview could not place the unlocked Cactus through BuildController")
		return
	await physics_frame

	# A --script SceneTree is not the normal project launcher, so explicitly mirror the
	# WaveDirector dependencies that its _ready() owns during a standard game launch.
	main.wave_director.arena_controller = main.arena_controller
	main.wave_director.player = main.player
	main.wave_director.core = main.core

	var markers: Array[Node2D] = main.arena_controller.get_markers(&"enemy_spawn")
	if markers.is_empty():
		_fail("Arena01 must expose enemy_spawn markers to the production WaveDirector")
		return

	var spawn_attempts: int = 0
	while main.wave_director.get_alive_enemy_count() < TARGET_ENEMIES_FOR_PREVIEW and spawn_attempts < MAX_SPAWN_ATTEMPTS:
		main.wave_director._spawn_next()
		await process_frame
		spawn_attempts += 1

	# Let the production Cactus target and fire long enough to create a genuine battle frame.
	for _i in range(44):
		await process_frame

	# Fire one real Prospector shot immediately before capture. The weapon signal drives the
	# authored rifle pose and production muzzle VFX.
	var target: EnemyBase = _nearest_enemy_to(main.player.global_position)
	var death_vfx_spawned := false
	if target != null:
		var direction := main.player.muzzle.global_position.direction_to(target.global_position)
		main.player.weapon_component.try_fire(main.player.muzzle.global_position, direction, main.player.team_component.team)
		await physics_frame
		await process_frame

		# Trigger one lethal hit through the production Hurtbox -> Health -> enemy_died chain so
		# the QA frame proves that real combat deaths create the authored shard/dust/light burst.
		var lethal_damage: float = target.health_component.current_health + 1.0
		target.hurtbox_component.receive_hit(lethal_damage, main.player.team_component.team)
		await process_frame
		death_vfx_spawned = not get_nodes_in_group("enemy_death_vfx").is_empty()

	if not death_vfx_spawned:
		_fail("Gameplay preview did not produce the production enemy death burst")
		return

	await RenderingServer.frame_post_draw

	var enemy_count: int = main.wave_director.get_alive_enemy_count()
	if enemy_count < MIN_ENEMIES_FOR_PREVIEW:
		_fail("Gameplay preview never reached sustained battle density: %d enemies (wave %d, attempts %d, markers %d)" % [enemy_count,main.wave_director.current_wave_number,spawn_attempts,markers.size()])
		return
	var defenses := get_nodes_in_group("defenses")
	if defenses.is_empty():
		_fail("Gameplay preview lost its production-built defense before capture")
		return

	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Viewport capture returned no image")
		return
	var err: Error = image.save_png(OUTPUT_PATH)
	if err != OK:
		_fail("Could not save gameplay preview: %s" % error_string(err))
		return
	print("PASS: gameplay preview saved with %d enemies, active Prospector rifle, production death burst and %d defenses to %s (%dx%d)" % [enemy_count,defenses.size(),OUTPUT_PATH,image.get_width(),image.get_height()])
	main.queue_free()
	quit(0)

func _nearest_enemy_to(origin: Vector2) -> EnemyBase:
	var nearest: EnemyBase
	var nearest_distance: float = INF
	for node in get_nodes_in_group("enemies"):
		if node is EnemyBase and is_instance_valid(node):
			var candidate := node as EnemyBase
			var distance: float = origin.distance_squared_to(candidate.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = candidate
	return nearest

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
