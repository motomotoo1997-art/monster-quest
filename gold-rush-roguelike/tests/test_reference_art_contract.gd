extends SceneTree

const ENEMIES := [
	{"scene":"res://scenes/enemies/GoldHopper.tscn","atlas":"enemies_reference_v5.svg"},
	{"scene":"res://scenes/enemies/GoldCoinSentinel.tscn","atlas":"enemies_reference_v5.svg"},
	{"scene":"res://scenes/enemies/FlyingGoldDisc.tscn","atlas":"enemies_reference_v5.svg"},
	{"scene":"res://scenes/enemies/MoltenGoldSlime.tscn","atlas":"enemies_reference_v5.svg"},
	{"scene":"res://scenes/enemies/GoldBarTank.tscn","atlas":"boss_frontier_juggernaut_v6.svg"},
]

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var arena_packed := load("res://scenes/arenas/Arena01.tscn") as PackedScene
	if arena_packed == null:
		_fail("Arena01 must load")
		return
	var arena := arena_packed.instantiate()
	root.add_child(arena)
	await process_frame
	var backdrop := arena.get_node_or_null("IllustratedBackdrop") as Sprite2D
	if backdrop == null or backdrop.texture == null:
		_fail("Arena01 reference backdrop missing")
		return
	if not backdrop.texture.resource_path.ends_with("arena01_frontier_street_v6.svg"):
		_fail("Arena01 must use the high-fidelity western gold-mine reference rebuild")
		return
	if backdrop.texture.get_width() < 1200:
		_fail("Arena01 reference backdrop must remain full-width")
		return
	for building_name in ["Saloon","SheriffOffice","FrontierBank","GeneralStore"]:
		var building := arena.get_node_or_null(building_name) as Sprite2D
		if building == null or building.texture == null or not building.visible:
			_fail("Arena01 must expose a clear standalone western building: %s" % building_name)
			return
	arena.queue_free()
	await process_frame

	for entry in ENEMIES:
		var packed := load(entry.scene) as PackedScene
		if packed == null:
			_fail("Enemy scene must load: %s" % entry.scene)
			return
		var enemy := packed.instantiate()
		root.add_child(enemy)
		await process_frame
		var sprite := enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if sprite == null or sprite.sprite_frames == null:
			_fail("Reference enemy sprite missing: %s" % entry.scene)
			return
		var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
		if texture == null:
			_fail("Reference enemy frame missing: %s" % entry.scene)
			return
		if texture is AtlasTexture:
			var atlas := (texture as AtlasTexture).atlas
			if atlas == null or not atlas.resource_path.ends_with(entry.atlas):
				_fail("Enemy must use reference-matched atlas %s: %s" % [entry.atlas, entry.scene])
				return
		else:
			_fail("Enemy reference frame must be atlas-backed: %s" % entry.scene)
			return
		enemy.queue_free()
		await process_frame

	print("PASS: Arena01 and enemy roster use the approved western reference art pass")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
