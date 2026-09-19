extends SceneTree

const MAIN_SCENE := "res://scenes/main/Main.tscn"
const HOPPER_SCENE := "res://scenes/enemies/GoldHopper.tscn"
const HIT_FLASH_SCENE := "res://scenes/vfx/HitFlash.tscn"

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var main_packed := load(MAIN_SCENE) as PackedScene
	if main_packed == null:
		_fail("Main scene must load for combat VFX regression")
		return
	var main := main_packed.instantiate() as GoldRushMain
	if main == null:
		_fail("Main scene must instantiate for combat VFX regression")
		return
	root.add_child(main)
	current_scene = main
	await process_frame

	if main.enemy_death_burst_scene == null:
		_fail("Main must expose an enemy death burst scene")
		return

	var death_vfx := main.enemy_death_burst_scene.instantiate() as Node2D
	if death_vfx == null:
		_fail("Enemy death burst scene must instantiate")
		return
	root.add_child(death_vfx)
	await process_frame
	if not death_vfx.is_in_group("enemy_death_vfx"):
		_fail("Enemy death burst must be discoverable as enemy_death_vfx")
		return
	var shards := death_vfx.get_node_or_null("GoldShards") as Node2D
	var shock_ring := death_vfx.get_node_or_null("ShockRing") as Line2D
	var dust := death_vfx.get_node_or_null("Dust") as CPUParticles2D
	if shards == null or shards.get_child_count() < 6:
		_fail("Enemy death burst needs at least six authored gold shards")
		return
	if shock_ring == null or shock_ring.width < 2.0:
		_fail("Enemy death burst needs a readable shock ring")
		return
	if dust == null or dust.amount < 8 or not dust.one_shot:
		_fail("Enemy death burst needs one-shot dust particles")
		return
	death_vfx.queue_free()
	await process_frame

	var hit_packed := load(HIT_FLASH_SCENE) as PackedScene
	if hit_packed == null:
		_fail("HitFlash scene must load")
		return
	var hit := hit_packed.instantiate() as Node2D
	root.add_child(hit)
	await process_frame
	var impact_ring := hit.get_node_or_null("ImpactRing") as Line2D
	var impact_sparks := hit.get_node_or_null("ImpactSparks") as Node2D
	if impact_ring == null or impact_ring.width < 2.0:
		_fail("HitFlash needs a cyan impact ring for readable hits")
		return
	if impact_sparks == null or impact_sparks.get_child_count() < 4:
		_fail("HitFlash needs multiple gold/cyan impact sparks")
		return
	hit.queue_free()
	await process_frame

	var hopper_packed := load(HOPPER_SCENE) as PackedScene
	var hopper := hopper_packed.instantiate() as EnemyBase if hopper_packed != null else null
	if hopper == null:
		_fail("GoldHopper must instantiate for enemy death VFX wiring")
		return
	main.add_child(hopper)
	await process_frame
	main._bind_enemy_feedback(hopper)
	hopper.enemy_died.emit(hopper, hopper.gold_value)
	await process_frame
	if get_nodes_in_group("enemy_death_vfx").is_empty():
		_fail("Enemy death signal must spawn production death VFX")
		return

	print("PASS: combat hits and enemy deaths produce layered production VFX")
	main.queue_free()
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
