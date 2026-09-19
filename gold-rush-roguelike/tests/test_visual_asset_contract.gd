extends SceneTree

const EXPECTED := [
	{"scene":"res://scenes/player/Prospector.tscn","visual":"BodyVisual","min_width":192.0,"min_display_width":220.0,"min_scale":0.40},
	{"scene":"res://scenes/enemies/GoldHopper.tscn","visual":"AnimatedSprite2D","min_width":300.0,"min_scale":0.30,"max_scale":0.36,"min_separation":36.0},
	{"scene":"res://scenes/enemies/GoldCoinSentinel.tscn","visual":"AnimatedSprite2D","min_width":300.0,"min_scale":0.34,"max_scale":0.38,"min_separation":42.0},
	{"scene":"res://scenes/enemies/FlyingGoldDisc.tscn","visual":"AnimatedSprite2D","min_width":300.0,"min_scale":0.28,"max_scale":0.32},
	{"scene":"res://scenes/enemies/MoltenGoldSlime.tscn","visual":"AnimatedSprite2D","min_width":300.0,"min_scale":0.34,"max_scale":0.40},
	{"scene":"res://scenes/enemies/GoldBarTank.tscn","visual":"AnimatedSprite2D","min_width":450.0,"min_scale":0.58},
	{"scene":"res://scenes/defenses/MagneticTurret.tscn","visual":"Visual","min_width":400.0,"min_scale":0.34},
	{"scene":"res://scenes/defenses/CactusSentry.tscn","visual":"Visual","min_width":400.0,"min_scale":0.32},
	{"scene":"res://scenes/defenses/TNTBarrel.tscn","visual":"Visual","min_width":400.0,"min_scale":0.32},
	{"scene":"res://scenes/objectives/GoldCore.tscn","visual":"Visual","min_width":256.0,"min_scale":0.25,"max_scale":0.55},
]

const ARENA_BACKDROPS := [
	{"scene":"res://scenes/arenas/Arena02.tscn","texture":"arena02_backdrop_v2.svg"},
	{"scene":"res://scenes/arenas/Arena03.tscn","texture":"arena03_backdrop_v2.svg"},
	{"scene":"res://scenes/arenas/Arena04.tscn","texture":"arena04_backdrop_v2.svg"},
	{"scene":"res://scenes/arenas/Arena05.tscn","texture":"arena05_backdrop_v2.svg"},
]

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	for entry in EXPECTED:
		var packed := load(entry.scene) as PackedScene
		if packed == null:
			_fail("Visual scene must load: %s" % entry.scene)
			return
		var instance := packed.instantiate()
		root.add_child(instance)
		await process_frame
		var visual := instance.get_node_or_null(entry.visual) as Node2D
		if visual == null:
			_fail("Visual node missing: %s/%s" % [entry.scene, entry.visual])
			return
		var texture: Texture2D
		if visual is AnimatedSprite2D:
			var sprite := visual as AnimatedSprite2D
			var frames := sprite.sprite_frames
			if frames == null or not frames.has_animation(sprite.animation):
				_fail("Animated visual has no active animation: %s" % entry.scene)
				return
			texture = frames.get_frame_texture(sprite.animation, 0)
		elif visual is Sprite2D:
			texture = (visual as Sprite2D).texture
		if texture == null:
			_fail("Visual texture missing: %s" % entry.scene)
			return
		if texture.get_width() < float(entry.min_width):
			_fail("Visual source resolution too small for %s" % entry.scene)
			return
		if absf(visual.scale.x) < float(entry.min_scale):
			_fail("Visual is too small/readability regression: %s" % entry.scene)
			return
		if entry.has("min_display_width"):
			var display_width := float(texture.get_width()) * absf(visual.scale.x)
			if display_width < float(entry.min_display_width):
				_fail("Visual display footprint is too small for gameplay readability: %s" % entry.scene)
				return
		if entry.has("max_scale") and absf(visual.scale.x) > float(entry.max_scale):
			_fail("Visual is too large/composition regression: %s" % entry.scene)
			return
		if instance is EnemyBase:
			if instance is FlyingGoldDisc:
				if instance.z_index <= 0:
					_fail("Flying enemy must stay above the grounded Y-sort layer: %s" % entry.scene)
					return
			elif instance.z_index != 0:
				_fail("Ground enemy must remain on the shared arena Y-sort z-index: %s" % entry.scene)
				return
			if entry.has("min_separation") and instance.separation_radius < float(entry.min_separation):
				_fail("Enemy crowd separation regressed: %s" % entry.scene)
				return
		instance.queue_free()
		await process_frame

	var core_packed := load("res://scenes/objectives/GoldCore.tscn") as PackedScene
	if core_packed == null:
		_fail("GoldCore scene must load")
		return
	var core := core_packed.instantiate()
	root.add_child(core)
	await process_frame
	var energy_rings := core.get_node_or_null("EnergyRings") as Node2D
	if energy_rings == null or energy_rings.get_child_count() < 2:
		_fail("GoldCore must have layered animated containment rings")
		return
	if not core.has_method("get_visual_pulse_phase"):
		_fail("GoldCore must expose deterministic pulse state for animation regression")
		return
	var pulse_a: float = core.get_visual_pulse_phase()
	await create_timer(0.12).timeout
	var pulse_b: float = core.get_visual_pulse_phase()
	if is_equal_approx(pulse_a, pulse_b):
		_fail("GoldCore containment energy must animate over time")
		return
	core.queue_free()
	await process_frame

	var arena_packed := load("res://scenes/arenas/Arena01.tscn") as PackedScene
	if arena_packed == null:
		_fail("Arena01 visual scene must load")
		return
	var arena := arena_packed.instantiate()
	root.add_child(arena)
	await process_frame
	var depth := arena.get_node_or_null("CanyonDepth") as Sprite2D
	if depth == null or depth.texture == null or depth.texture.get_width() < 1000:
		_fail("Arena01 must contain a full-width illustrated CanyonDepth layer")
		return
	var dust := arena.get_node_or_null("AmbientDust") as CPUParticles2D
	if dust == null:
		_fail("Arena01 must contain AmbientDust CPUParticles2D atmosphere")
		return
	if dust.amount < 20 or dust.lifetime < 2.0:
		_fail("Arena01 ambient dust is too sparse to create depth")
		return
	arena.queue_free()
	await process_frame

	for arena_entry in ARENA_BACKDROPS:
		var late_arena_packed := load(arena_entry.scene) as PackedScene
		if late_arena_packed == null:
			_fail("Arena visual scene must load: %s" % arena_entry.scene)
			return
		var late_arena := late_arena_packed.instantiate()
		root.add_child(late_arena)
		await process_frame
		var backdrop := late_arena.get_node_or_null("IllustratedBackdrop") as Sprite2D
		if backdrop == null or backdrop.texture == null:
			_fail("Arena must contain an illustrated backdrop: %s" % arena_entry.scene)
			return
		if not backdrop.texture.resource_path.ends_with(arena_entry.texture):
			_fail("Arena must use unique late-run backdrop: %s" % arena_entry.texture)
			return
		if backdrop.texture.get_width() < 1000:
			_fail("Late-run backdrop must remain full-width: %s" % arena_entry.texture)
			return
		late_arena.queue_free()
		await process_frame

	var hud_packed := load("res://scenes/ui/HUD.tscn") as PackedScene
	if hud_packed == null:
		_fail("HUD scene must load")
		return
	var hud := hud_packed.instantiate()
	root.add_child(hud)
	await process_frame
	var top_left := hud.get_node_or_null("Root/TopLeftBackdrop") as Control
	var bottom_center := hud.get_node_or_null("Root/BottomCenter") as Control
	if top_left == null or bottom_center == null:
		_fail("HUD compact panels are missing")
		return
	if top_left.size.x > 250.0:
		_fail("Top-left HUD consumes too much combat view")
		return
	if bottom_center.size.x > 420.0:
		_fail("Build HUD consumes too much horizontal combat view")
		return
	hud.queue_free()
	await process_frame

	print("PASS: actors, containment animation, crowd spacing, arena art, atmosphere and compact HUD remain readable")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
