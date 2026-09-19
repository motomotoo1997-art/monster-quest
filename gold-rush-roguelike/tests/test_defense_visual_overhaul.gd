extends SceneTree

const ATLAS_PATH := "res://assets/sprites/defenses/defenses_frontier_v6.svg"
const CASES := [
	{"scene":"res://scenes/defenses/MagneticTurret.tscn","required":["EnergyLight","AimPivot/Muzzle"]},
	{"scene":"res://scenes/defenses/CactusSentry.tscn","required":["EnergyLight","AimPivot/Muzzle"]},
	{"scene":"res://scenes/defenses/TNTBarrel.tscn","required":["FuseGlow"]},
]

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	for entry in CASES:
		var packed := load(entry.scene) as PackedScene
		if packed == null:
			_fail("Defense scene must load: %s" % entry.scene)
			return
		var defense := packed.instantiate()
		root.add_child(defense)
		await process_frame
		var visual := defense.get_node_or_null("Visual") as AnimatedSprite2D
		if visual == null or visual.sprite_frames == null:
			_fail("Defense must have animated Visual: %s" % entry.scene)
			return
		for animation_name in visual.sprite_frames.get_animation_names():
			for frame_index in range(visual.sprite_frames.get_frame_count(animation_name)):
				var frame := visual.sprite_frames.get_frame_texture(animation_name, frame_index) as AtlasTexture
				if frame == null or frame.atlas == null or frame.atlas.resource_path != ATLAS_PATH:
					_fail("Defense must use frontier v6 atlas: %s/%s" % [entry.scene, animation_name])
					return
		var shadow := defense.get_node_or_null("Shadow") as Polygon2D
		if shadow == null or shadow.polygon.size() < 6:
			_fail("Defense must keep a readable contact shadow: %s" % entry.scene)
			return
		for node_path in entry.required:
			if defense.get_node_or_null(node_path) == null:
				_fail("Defense presentation node missing: %s/%s" % [entry.scene, node_path])
				return
		defense.queue_free()
		await process_frame
	print("PASS: defenses use frontier v6 art and retain readable firing/arming accents")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
