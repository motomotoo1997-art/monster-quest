extends SceneTree

const ATLAS_PATH := "res://assets/sprites/enemies/enemies_frontier_v6.svg"
const CASES := [
	{"scene":"res://scenes/enemies/GoldHopper.tscn","shadow_y_min":10.0},
	{"scene":"res://scenes/enemies/GoldCoinSentinel.tscn","shadow_y_min":12.0,"accent":"EmitterGlow"},
	{"scene":"res://scenes/enemies/FlyingGoldDisc.tscn","shadow_y_min":22.0,"accent":"EngineGlow"},
	{"scene":"res://scenes/enemies/MoltenGoldSlime.tscn","shadow_y_min":12.0,"accent":"CoreGlow"},
]

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	for entry in CASES:
		var packed := load(entry.scene) as PackedScene
		if packed == null:
			_fail("Enemy scene must load: %s" % entry.scene)
			return
		var enemy := packed.instantiate()
		root.add_child(enemy)
		await process_frame
		var sprite := enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if sprite == null or sprite.sprite_frames == null:
			_fail("Enemy needs AnimatedSprite2D: %s" % entry.scene)
			return
		for animation_name in sprite.sprite_frames.get_animation_names():
			for frame_index in range(sprite.sprite_frames.get_frame_count(animation_name)):
				var frame := sprite.sprite_frames.get_frame_texture(animation_name, frame_index) as AtlasTexture
				if frame == null or frame.atlas == null or frame.atlas.resource_path != ATLAS_PATH:
					_fail("Enemy must use frontier v6 atlas: %s/%s" % [entry.scene, animation_name])
					return
		var shadow := enemy.get_node_or_null("Shadow") as Polygon2D
		if shadow == null or shadow.polygon.size() < 6 or shadow.position.y < float(entry.shadow_y_min):
			_fail("Enemy needs a readable grounded shadow: %s" % entry.scene)
			return
		if entry.has("accent"):
			var accent := enemy.get_node_or_null(entry.accent) as CanvasItem
			if accent == null:
				_fail("Enemy presentation accent missing: %s/%s" % [entry.scene, entry.accent])
				return
		if entry.scene.ends_with("FlyingGoldDisc.tscn") and shadow.position.y - sprite.position.y < 55.0:
			_fail("FlyingGoldDisc shadow must remain clearly separated from the airborne sprite")
			return
		enemy.queue_free()
		await process_frame
	print("PASS: normal enemy roster uses the frontier v6 art and grounded silhouettes")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
