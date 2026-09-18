extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("SCREENSHOT: main scene failed to load")
		quit(1)
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	await process_frame
	var world: Node2D = instance.get_node("World")
	var placements := [
		["res://scenes/enemies/chicken.tscn", Vector2(180, 40)],
		["res://scenes/enemies/chicken.tscn", Vector2(280, 120)],
		["res://scenes/enemies/boar.tscn", Vector2(390, -20)],
		["res://scenes/enemies/neighbor.tscn", Vector2(-230, 150)],
		["res://scenes/enemies/king_boar.tscn", Vector2(500, 150)],
		["res://scenes/td/turret.tscn", Vector2(-130, -20)],
		["res://scenes/td/brazier.tscn", Vector2(30, -90)],
		["res://scenes/td/fridge.tscn", Vector2(-260, -70)],
		["res://scenes/td/barricade.tscn", Vector2(120, 175)]
	]
	for entry in placements:
		var scene := load(entry[0]) as PackedScene
		var node := scene.instantiate()
		node.global_position = entry[1]
		world.add_child(node)
	instance.wave = 5
	instance.wave_time = 23.0
	instance.call("_update_hud")
	for i in 12:
		await process_frame
	var output_dir := ProjectSettings.globalize_path("res://artifacts")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := root.get_texture().get_image()
	var error := image.save_png(output_dir.path_join("ci_preview.png"))
	if error != OK:
		push_error("SCREENSHOT: save_png failed with %s" % error)
		quit(1)
		return
	print("SCREENSHOT_OK: res://artifacts/ci_preview.png")
	quit(0)
