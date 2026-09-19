extends SceneTree

const ATLAS_PATH := "res://assets/sprites/defenses/defenses_frontier_v6.svg"
const EXPECTED := [
	{"scene":"res://scenes/defenses/MagneticTurret.tscn","animations":{&"idle":3,&"fire":3}},
	{"scene":"res://scenes/defenses/CactusSentry.tscn","animations":{&"idle":2,&"fire":3}},
	{"scene":"res://scenes/defenses/TNTBarrel.tscn","animations":{&"prearm":2,&"armed":3}},
]

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	for entry in EXPECTED:
		var packed := load(entry.scene) as PackedScene
		if packed == null:
			_fail("Defense scene must load: %s" % entry.scene)
			return
		var defense := packed.instantiate()
		root.add_child(defense)
		await process_frame
		var visual := defense.get_node_or_null("Visual") as AnimatedSprite2D
		if visual == null or visual.sprite_frames == null:
			_fail("Defense Visual must be AnimatedSprite2D: %s" % entry.scene)
			return
		var frames := visual.sprite_frames
		for animation_name in entry.animations:
			if not frames.has_animation(animation_name):
				_fail("Defense animation missing: %s/%s" % [entry.scene, animation_name])
				return
			var required_count: int = int(entry.animations[animation_name])
			var frame_count := frames.get_frame_count(animation_name)
			if frame_count < required_count:
				_fail("Defense %s needs %d frames for %s, found %d" % [entry.scene, required_count, animation_name, frame_count])
				return
			if frames.get_animation_speed(animation_name) < 5.0:
				_fail("Defense animation FPS too low: %s/%s" % [entry.scene, animation_name])
				return
			var unique_regions := {}
			for frame_index in range(frame_count):
				var atlas_texture := frames.get_frame_texture(animation_name, frame_index) as AtlasTexture
				if atlas_texture == null or atlas_texture.atlas == null:
					_fail("Defense frame must use AtlasTexture: %s/%s" % [entry.scene, animation_name])
					return
				if atlas_texture.atlas.resource_path != ATLAS_PATH:
					_fail("Defense must use shared production atlas: %s" % entry.scene)
					return
				unique_regions[atlas_texture.region] = true
			if unique_regions.size() < required_count:
				_fail("Defense animation reuses duplicate regions: %s/%s" % [entry.scene, animation_name])
				return
		defense.queue_free()
		await process_frame
	print("PASS: defenses use distinct recoil, fire and armed animation frames")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
