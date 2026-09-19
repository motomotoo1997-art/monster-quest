extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene must load")
		return
	var main := packed.instantiate() as GoldRushMain
	root.add_child(main)
	current_scene = main
	await process_frame
	main._on_start_requested()
	await process_frame
	await physics_frame
	var enemies := get_nodes_in_group("enemies")
	if enemies.size() < 3:
		_fail("Production Arena01 must show an opening enemy group immediately; found %d" % enemies.size())
		return
	var visible_count := 0
	for node in enemies:
		if node is CanvasItem and (node as CanvasItem).visible:
			visible_count += 1
	if visible_count < 3:
		_fail("Opening production enemies must be visible; visible=%d" % visible_count)
		return
	main.queue_free()
	print("PASS: production start immediately shows at least three visible enemies")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
