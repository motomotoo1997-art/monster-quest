extends SceneTree

const ARENA_SCENE := "res://scenes/arenas/Arena05.tscn"
const BOSS_SCENE := "res://scenes/enemies/GoldBarTank.tscn"
const BACKDROP := "res://assets/environment/arena05_molten_foundry_v6.svg"

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var arena_packed := load(ARENA_SCENE) as PackedScene
	if arena_packed == null:
		_fail("Arena05 scene must load")
		return
	var arena := arena_packed.instantiate()
	root.add_child(arena)
	await process_frame
	var backdrop := arena.get_node_or_null("IllustratedBackdrop") as Sprite2D
	if backdrop == null or backdrop.texture == null or backdrop.texture.resource_path != BACKDROP:
		_fail("Arena05 must use the molten foundry v6 backdrop")
		return
	for landmark_path in ["FoundryFurnace","FoundryGantry"]:
		var landmark := arena.get_node_or_null(landmark_path) as Sprite2D
		if landmark == null or landmark.texture == null or not landmark.visible:
			_fail("Arena05 landmark missing: %s" % landmark_path)
			return
	var boss_spawn := arena.get_node_or_null("BossSpawn") as Marker2D
	if boss_spawn == null:
		_fail("Arena05 must preserve BossSpawn")
		return
	if boss_spawn.position.x < 760.0 or boss_spawn.position.x > 1040.0 or absf(boss_spawn.position.y - 360.0) > 90.0:
		_fail("BossSpawn must stay inside the readable central-right combat lane")
		return
	var furnace := arena.get_node("FoundryFurnace") as Sprite2D
	if furnace.position.distance_to(boss_spawn.position) < 220.0:
		_fail("Bright furnace landmark must remain outside boss silhouette clearance")
		return
	arena.queue_free()
	await process_frame

	var boss_packed := load(BOSS_SCENE) as PackedScene
	if boss_packed == null:
		_fail("Frontier Juggernaut scene must load")
		return
	var boss := boss_packed.instantiate()
	root.add_child(boss)
	await process_frame
	var shadow := boss.get_node_or_null("Shadow") as Polygon2D
	if shadow == null or shadow.polygon.size() < 8 or shadow.color.a < 0.32:
		_fail("Frontier Juggernaut needs a strong contact shadow")
		return
	var core_glow := boss.get_node_or_null("CoreGlow") as Polygon2D
	if core_glow == null or core_glow.color.a < 0.28:
		_fail("Frontier Juggernaut needs a readable emissive core accent")
		return
	var warning := boss.get_node_or_null("ChargeTelegraph/WarningLine") as Line2D
	var beam := boss.get_node_or_null("ChargeTelegraph/BeamCore") as Line2D
	if warning == null or beam == null or warning.width >= beam.width:
		_fail("Boss warning line must remain thinner than the firing beam")
		return
	var slam_ring := boss.get_node_or_null("SlamTelegraph/Ring") as Polygon2D
	var slam_outline := boss.get_node_or_null("SlamTelegraph/Outline") as Line2D
	if slam_ring == null or slam_ring.color.a > 0.14:
		_fail("Boss slam fill must stay translucent enough to preserve the silhouette")
		return
	if slam_outline == null or slam_outline.width < 4.0 or slam_outline.default_color.a < 0.60:
		_fail("Boss slam warning needs a strong perimeter instead of an opaque floor wash")
		return
	boss.state = GoldBarTank.State.SLAM
	boss.slam_telegraph.visible = true
	var max_slam_energy := 0.0
	var max_slam_scale := 0.0
	for _frame in range(120):
		boss._update_visual(0.016)
		max_slam_energy = maxf(max_slam_energy, boss.slam_light.energy)
		max_slam_scale = maxf(max_slam_scale, boss.slam_light.texture_scale)
	if max_slam_energy > 1.72 or max_slam_scale > 1.38:
		_fail("Boss slam warning must not wash out the Juggernaut silhouette")
		return
	boss.queue_free()
	print("PASS: Arena05 foundry preserves boss clearance and Frontier Juggernaut attack readability")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
