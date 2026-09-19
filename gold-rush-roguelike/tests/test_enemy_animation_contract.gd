extends SceneTree

const ATLAS_PATH := "res://assets/sprites/enemies/enemies_animation_v4.svg"
const EXPECTED := [
	{"scene":"res://scenes/enemies/GoldHopper.tscn","animations":{&"idle":2,&"move":4,&"hop":4}},
	{"scene":"res://scenes/enemies/GoldCoinSentinel.tscn","animations":{&"idle":3,&"move":3,&"attack":3}},
	{"scene":"res://scenes/enemies/FlyingGoldDisc.tscn","animations":{&"idle":4,&"move":4,&"attack":3}},
	{"scene":"res://scenes/enemies/MoltenGoldSlime.tscn","animations":{&"idle":3,&"move":4}},
]

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	for entry in EXPECTED:
		var packed := load(entry.scene) as PackedScene
		if packed == null:
			_fail("Enemy scene must load: %s" % entry.scene)
			return
		var enemy := packed.instantiate()
		root.add_child(enemy)
		await process_frame
		var sprite := enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if sprite == null or sprite.sprite_frames == null:
			_fail("Enemy must use AnimatedSprite2D with SpriteFrames: %s" % entry.scene)
			return
		var frames := sprite.sprite_frames
		for animation_name in entry.animations:
			if not frames.has_animation(animation_name):
				_fail("Enemy animation missing: %s/%s" % [entry.scene, animation_name])
				return
			var required_count: int = int(entry.animations[animation_name])
			var frame_count := frames.get_frame_count(animation_name)
			if frame_count < required_count:
				_fail("Enemy %s needs %d frames for %s, found %d" % [entry.scene, required_count, animation_name, frame_count])
				return
			if frames.get_animation_speed(animation_name) < 5.0:
				_fail("Enemy animation FPS too low: %s/%s" % [entry.scene, animation_name])
				return
			var unique_regions := {}
			for frame_index in range(frame_count):
				var atlas_texture := frames.get_frame_texture(animation_name, frame_index) as AtlasTexture
				if atlas_texture == null or atlas_texture.atlas == null:
					_fail("Enemy frame must use AtlasTexture: %s/%s" % [entry.scene, animation_name])
					return
				if atlas_texture.atlas.resource_path != ATLAS_PATH:
					_fail("Enemy animation must use shared production atlas: %s" % entry.scene)
					return
				unique_regions[atlas_texture.region] = true
			if unique_regions.size() < required_count:
				_fail("Enemy animation reuses duplicate frames: %s/%s" % [entry.scene, animation_name])
				return
		enemy.queue_free()
		await process_frame
	print("PASS: normal enemies use distinct production multi-frame animations")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
