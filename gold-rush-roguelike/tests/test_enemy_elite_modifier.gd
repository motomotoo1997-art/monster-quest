extends SceneTree

const SENTINEL_SCENE := preload("res://scenes/enemies/GoldCoinSentinel.tscn")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var enemy := SENTINEL_SCENE.instantiate() as EnemyBase
	if enemy == null:
		_fail("Sentinel must instantiate as EnemyBase")
		return
	root.add_child(enemy)
	await process_frame

	if not enemy.has_method("apply_elite_modifier"):
		_fail("EnemyBase must expose apply_elite_modifier for authored elite waves")
		return

	var base_health := enemy.health_component.max_health
	var base_damage := enemy.contact_damage
	var base_gold := enemy.gold_value
	var base_speed := enemy.move_speed
	enemy.call("apply_elite_modifier")

	if not enemy.is_in_group("elite_enemies"):
		_fail("Elite enemies need a dedicated runtime group")
		return
	if enemy.health_component.max_health < base_health * 1.55:
		_fail("Elite health must be meaningfully higher")
		return
	if enemy.contact_damage < base_damage * 1.20:
		_fail("Elite contact damage must be meaningfully higher")
		return
	if enemy.move_speed < base_speed * 1.05:
		_fail("Elite movement must be visibly more threatening")
		return
	if enemy.gold_value < base_gold * 2:
		_fail("Elite enemies must reward at least double gold")
		return
	var drop := enemy.get_node_or_null("GoldDropComponent") as GoldDropComponent
	if drop == null or drop.gold_amount != enemy.gold_value:
		_fail("Elite gold drop must stay synchronized with gold_value")
		return
	var aura := enemy.get_node_or_null("EliteAura") as CanvasItem
	if aura == null or not aura.visible:
		_fail("Elite enemies need a readable authored aura")
		return

	var main_scene := load("res://scenes/main/Main.tscn") as PackedScene
	var main := main_scene.instantiate() as GoldRushMain
	root.add_child(main)
	await process_frame
	for arena_index in [1, 2]:
		if _count_elite_entries(main._build_arena_waves(arena_index)) != 0:
			_fail("Early arenas must teach the base roster before elites appear")
			return
	if _count_elite_entries(main._build_arena_waves(3)) < 1:
		_fail("Arena03 must introduce at least one elite wave entry")
		return
	if _count_elite_entries(main._build_arena_waves(4)) < 2:
		_fail("Arena04 must escalate with multiple elite wave entries")
		return

	enemy.queue_free()
	main.queue_free()
	print("PASS: elite enemy modifiers are rewarding, readable, and authored into late-run waves")
	quit(0)

func _count_elite_entries(waves: Array) -> int:
	var total := 0
	for wave in waves:
		if not wave is Array:
			continue
		for entry in wave:
			if entry is Dictionary and bool((entry as Dictionary).get("elite", false)):
				total += int((entry as Dictionary).get("count", 1))
	return total

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
