extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene must load")
		return
	var main := packed.instantiate() as GoldRushMain
	root.add_child(main)
	await process_frame

	var upgrades := main.upgrade_controller
	if upgrades == null:
		_fail("UpgradeController must exist")
		return
	if upgrades._find_definition(&"trailblazer") == null:
		_fail("Upgrade pool must include Trailblazer movement upgrade")
		return
	if upgrades._find_definition(&"piercing_rounds") == null:
		_fail("Upgrade pool must include Piercing Rounds")
		return

	var base_speed := main.player.move_speed
	upgrades.apply_upgrade(&"trailblazer")
	if main.player.move_speed < base_speed * 1.10:
		_fail("Trailblazer must meaningfully increase Prospector movement speed")
		return

	var weapon := main.player.weapon_component
	var base_pierce := weapon.projectile_pierce
	upgrades.apply_upgrade(&"piercing_rounds")
	if weapon.projectile_pierce < base_pierce + 1:
		_fail("Piercing Rounds must add at least one enemy penetration")
		return

	var projectile_scene := weapon.projectile_scene
	var projectile := projectile_scene.instantiate() as ProjectileComponent
	if projectile == null:
		_fail("Player projectile must instantiate as ProjectileComponent")
		return
	root.add_child(projectile)
	projectile.configure(Vector2.RIGHT,500.0,10.0,TeamComponent.Team.PLAYER)
	projectile.pierce_remaining = weapon.projectile_pierce
	if projectile.pierce_remaining < 1:
		_fail("Projectile must receive the upgraded pierce budget")
		return
	projectile.queue_free()
	main.queue_free()
	print("PASS: new movement and piercing upgrades alter real combat stats")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
