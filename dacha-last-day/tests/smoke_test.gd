extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("SMOKE: main scene did not load")
		quit(1)
		return
	var instance := packed.instantiate()
	if instance == null:
		push_error("SMOKE: main scene did not instantiate")
		quit(1)
		return
	root.add_child(instance)
	await process_frame
	await process_frame
	print("SMOKE_OK: main scene loaded and processed two frames")
	instance.queue_free()
	quit(0)
