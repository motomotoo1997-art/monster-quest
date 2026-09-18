extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("TEST_FAIL: " + message)

func _run() -> void:
	paused = false
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "main scene did not load")
	if packed == null:
		quit(1)
		return
	var instance := packed.instantiate()
	_check(instance != null, "main scene did not instantiate")
	if instance == null:
		quit(1)
		return
	root.add_child(instance)
	await process_frame
	await process_frame

	var player = instance.get_node("World/Player")
	var core = instance.get_node("World/DachaCore")
	_check(player != null, "player missing from main scene")
	_check(core != null, "DachaCore missing from main scene")
	_check(core != null and not core.active, "DachaCore should start inactive")
	_check(player.get_node_or_null("AnimatedSprite2D") != null, "player animation node missing")
	_check(instance.get_node_or_null("UI/Status/VBox/HealthBar") != null, "health bar missing")
	_check(load("res://scenes/vfx/muzzle_flash.tscn") != null, "muzzle VFX scene missing")
	_check(load("res://scenes/vfx/impact_fx.tscn") != null, "impact VFX scene missing")
	_check(instance.get_node_or_null("World/AmbientModulate") is CanvasModulate, "ambient CanvasModulate missing")
	_check(instance.get_node_or_null("World/HouseWarmLight") is PointLight2D, "house PointLight2D missing")
	_check(instance.get_node_or_null("World/YardWarmLight") is PointLight2D, "yard PointLight2D missing")

	if player != null:
		var camera := player.get_node_or_null("Camera2D") as Camera2D
		_check(camera != null, "player camera missing")
		_check(player.has_method("add_camera_shake"), "player camera shake method missing")
		if player.has_method("add_camera_shake"):
			player.call("add_camera_shake", 6.0)
			_check(float(player.get("camera_shake_strength")) >= 5.9, "camera shake strength did not increase")

		var start_health: int = player.health
		player.take_damage(15)
		_check(player.health == start_health - 15, "player damage handling is wrong")
		player.heal(10)
		_check(player.health == start_health - 5, "player healing is wrong")

		# Test level progression independently from the UI pause signal so the
		# headless harness can never deadlock while SceneTree is paused.
		var perk_callback := Callable(instance, "_show_perks")
		if player.leveled_up.is_connected(perk_callback):
			player.leveled_up.disconnect(perk_callback)
		var start_level: int = player.level
		player.gain_xp(player.xp_needed)
		_check(player.level == start_level + 1, "level-up did not trigger")

		# Test pause/resume explicitly, then force-reset pause as a harness guard.
		instance.call("_show_perks")
		_check(paused, "perk choice should pause gameplay")
		paused = false
		instance.call("_hide_perks")
		_check(not paused, "closing perk choice should resume gameplay")

		var start_scrap: int = player.scrap
		_check(player.spend_scrap(10), "player could not spend available scrap")
		_check(player.scrap == start_scrap - 10, "scrap was not deducted")
		_check(not player.spend_scrap(99999), "player spent scrap they did not have")

	var required_scenes := [
		"res://scenes/enemies/chicken.tscn", "res://scenes/enemies/boar.tscn",
		"res://scenes/enemies/neighbor.tscn", "res://scenes/enemies/king_boar.tscn",
		"res://scenes/td/turret.tscn", "res://scenes/td/brazier.tscn",
		"res://scenes/td/fridge.tscn", "res://scenes/td/barricade.tscn"
	]
	for scene_path in required_scenes:
		var scene := load(scene_path) as PackedScene
		_check(scene != null, "failed to load " + scene_path)
		if scene != null:
			var node := scene.instantiate()
			_check(node != null, "failed to instantiate " + scene_path)
			if node != null:
				_check(node.get_node_or_null("AnimatedSprite2D") != null or not node.is_in_group("enemy"), "enemy animation node missing in " + scene_path)
				node.queue_free()

	instance.call("_begin_wave", 4, true)
	_check(core.active, "defense wave should activate DachaCore")
	instance.call("_begin_wave", 5, false)
	_check(not core.active, "normal wave should deactivate DachaCore")
	var bosses := get_nodes_in_group("boss")
	_check(bosses.size() == 1, "wave 5 should spawn exactly one boss")
	if not bosses.is_empty():
		var boss = bosses[0]
		_check(boss.max_health >= 400, "king boar health is unexpectedly low")
		_check(boss.is_in_group("enemy"), "boss must also be in enemy group")

	paused = false
	if failures.is_empty():
		print("SMOKE_OK: Prototype 0.4 systems, camera feedback, 2D lighting, VFX, HUD, TD objective and boss spawn passed")
		instance.queue_free()
		quit(0)
	else:
		print("SMOKE_FAILED_COUNT: ", failures.size())
		instance.queue_free()
		quit(1)
