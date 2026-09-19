extends SceneTree

const OUTPUT_PATH := "/tmp/gold-rush-gameplay-preview.png"
const MIN_ENEMIES_FOR_PREVIEW := 10
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
	await process_frame
	main._on_start_requested()
	paused = false
	main.player.set_input_enabled(false)
	await process_frame

	# A --script SceneTree is not the normal project launcher, so explicitly mirror the
	# WaveDirector dependencies that its _ready() owns during a standard game launch.
	# Spawning still goes through the real production queue and _spawn_next() path.
	main.wave_director.arena_controller = main.arena_controller
	main.wave_director.player = main.player
	main.wave_director.core = main.core

	var markers: Array[Node2D] = main.arena_controller.get_markers(&"enemy_spawn")
	if markers.is_empty():
		_fail("Arena01 must expose enemy_spawn markers to the production WaveDirector")
		return

	var spawn_attempts: int = 0
	while main.wave_director.get_alive_enemy_count() < MIN_ENEMIES_FOR_PREVIEW and spawn_attempts < MAX_SPAWN_ATTEMPTS:
		main.wave_director._spawn_next()
		await process_frame
		spawn_attempts += 1

	# Let y-sort, enemy visual animation and the viewport render settle.
	for _i in range(22):
		await process_frame
	await RenderingServer.frame_post_draw

	var enemy_count: int = main.wave_director.get_alive_enemy_count()
	if enemy_count < MIN_ENEMIES_FOR_PREVIEW:
		_fail("Gameplay preview never reached battle density: %d enemies (wave %d, attempts %d, markers %d)" % [enemy_count,main.wave_director.current_wave_number,spawn_attempts,markers.size()])
		return

	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Viewport capture returned no image")
		return
	var err: Error = image.save_png(OUTPUT_PATH)
	if err != OK:
		_fail("Could not save gameplay preview: %s" % error_string(err))
		return
	print("PASS: gameplay preview saved with %d enemies after %d spawn attempts to %s (%dx%d)" % [enemy_count,spawn_attempts,OUTPUT_PATH,image.get_width(),image.get_height()])
	main.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
