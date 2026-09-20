extends SceneTree

const PROJECTILE_SCENE := preload("res://scenes/combat/Projectile.tscn")
const HOPPER_SCENE := preload("res://scenes/enemies/GoldHopper.tscn")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var projectile := PROJECTILE_SCENE.instantiate() as ProjectileComponent
	var enemy := HOPPER_SCENE.instantiate() as EnemyBase
	if projectile == null or enemy == null:
		_fail("Combat feedback fixtures must instantiate")
		return
	root.add_child(enemy)
	root.add_child(projectile)
	await process_frame

	if not projectile.has_method("set_shot_traits"):
		_fail("Projectile must expose shot traits for crit/pierce feedback")
		return
	var pierce_halo := projectile.get_node_or_null("PierceHalo") as CanvasItem
	var crit_core := projectile.get_node_or_null("CritCore") as CanvasItem
	if pierce_halo == null or crit_core == null:
		_fail("Projectile needs authored PierceHalo and CritCore feedback nodes")
		return

	projectile.configure(Vector2.RIGHT,900.0,24.0,TeamComponent.Team.PLAYER)
	projectile.call("set_shot_traits",true,1)
	if not pierce_halo.visible or not crit_core.visible or projectile.pierce_remaining != 1:
		_fail("Critical piercing shots must visibly advertise both traits")
		return

	var health_before := enemy.health_component.current_health
	projectile._on_area_entered(enemy.hurtbox_component)
	await process_frame
	if enemy.health_component.current_health >= health_before:
		_fail("Feedback changes must preserve real projectile damage")
		return
	if projectile.pierce_remaining != 0 or projectile.is_queued_for_deletion():
		_fail("First piercing hit must consume one pierce and keep the projectile alive")
		return

	var impact_found := false
	for child in root.get_children():
		if child.name.begins_with("HitFlash"):
			impact_found = true
			break
	if not impact_found:
		_fail("Successful projectile hits must spawn impact feedback")
		return

	projectile._on_area_entered(enemy.hurtbox_component)
	if projectile.is_queued_for_deletion():
		_fail("Repeated overlap with the same hurtbox must not consume the projectile")
		return

	projectile.queue_free()
	enemy.queue_free()
	print("PASS: crit and piercing shots are readable and spawn hit feedback without changing hit semantics")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
