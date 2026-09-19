extends SceneTree

const EXPECTED := [
	{"scene":"res://scenes/player/Prospector.tscn","visual":"BodyVisual","min_width":300.0,"min_scale":0.40},
	{"scene":"res://scenes/enemies/GoldHopper.tscn","visual":"AnimatedSprite2D","min_width":300.0,"min_scale":0.30},
	{"scene":"res://scenes/enemies/GoldCoinSentinel.tscn","visual":"AnimatedSprite2D","min_width":300.0,"min_scale":0.34},
	{"scene":"res://scenes/enemies/FlyingGoldDisc.tscn","visual":"AnimatedSprite2D","min_width":300.0,"min_scale":0.38},
	{"scene":"res://scenes/enemies/MoltenGoldSlime.tscn","visual":"AnimatedSprite2D","min_width":300.0,"min_scale":0.34},
	{"scene":"res://scenes/enemies/GoldBarTank.tscn","visual":"AnimatedSprite2D","min_width":450.0,"min_scale":0.58},
	{"scene":"res://scenes/defenses/MagneticTurret.tscn","visual":"Visual","min_width":400.0,"min_scale":0.34},
	{"scene":"res://scenes/defenses/CactusSentry.tscn","visual":"Visual","min_width":400.0,"min_scale":0.32},
	{"scene":"res://scenes/defenses/TNTBarrel.tscn","visual":"Visual","min_width":400.0,"min_scale":0.32},
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
		if instance is EnemyBase and instance.z_index < 3:
			_fail("Enemy readability z-index regressed: %s" % entry.scene)
			return
		instance.queue_free()
		await process_frame
	print("PASS: reference-matched actor and defense visuals remain readable")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
