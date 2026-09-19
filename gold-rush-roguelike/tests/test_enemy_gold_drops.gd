extends SceneTree

const ENEMY_SCENES := [
	"res://scenes/enemies/GoldHopper.tscn",
	"res://scenes/enemies/GoldCoinSentinel.tscn",
	"res://scenes/enemies/FlyingGoldDisc.tscn",
	"res://scenes/enemies/MoltenGoldSlime.tscn",
]


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	for scene_path in ENEMY_SCENES:
		var scene := load(scene_path) as PackedScene
		if scene == null:
			_fail("Enemy scene must load: %s" % scene_path)
			return
		var enemy := scene.instantiate() as EnemyBase
		if enemy == null:
			_fail("Enemy scene must instantiate as EnemyBase: %s" % scene_path)
			return
		root.add_child(enemy)
		await process_frame
		var drop := enemy.get_node_or_null("GoldDropComponent") as GoldDropComponent
		if drop == null:
			_fail("Enemy must own GoldDropComponent: %s" % scene_path)
			return
		if drop.pickup_scene == null:
			_fail("GoldDropComponent must have a pickup scene: %s" % scene_path)
			return
		if drop.gold_amount != enemy.gold_value:
			_fail("Gold drop must match enemy gold_value: %s" % scene_path)
			return
		var expected_gold := drop.gold_amount
		enemy.health_component.damage(enemy.health_component.max_health)
		await process_frame
		var found_pickup := false
		for child in root.get_children():
			if child is GoldPickup and (child as GoldPickup).amount == expected_gold:
				found_pickup = true
				child.queue_free()
				break
		if not found_pickup:
			_fail("Enemy death must spawn configured GoldPickup: %s" % scene_path)
			return
		await process_frame

	print("PASS: normal enemy deaths spawn spendable gold pickups")
	quit(0)


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
