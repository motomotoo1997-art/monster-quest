extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var scene := load("res://scenes/enemies/GoldBarTank.tscn") as PackedScene
	if scene == null:
		_fail("GoldBarTank scene must load")
		return
	var boss := scene.instantiate() as GoldBarTank
	if boss == null:
		_fail("GoldBarTank scene must instantiate")
		return
	root.add_child(boss)
	await process_frame

	boss.phase = 1
	boss.state = GoldBarTank.State.CHASE
	boss._update_visual(0.0)
	if not _check(boss.visual_sprite.animation == &"idle", "CHASE must use idle presentation"):
		return

	boss.state = GoldBarTank.State.CHARGE_TELEGRAPH
	boss._update_visual(0.0)
	if not _check(boss.visual_sprite.animation == &"charge", "Laser telegraph must use charge presentation"):
		return

	boss.state = GoldBarTank.State.CHARGE
	boss._update_visual(0.0)
	if not _check(boss.visual_sprite.animation == &"fire", "Laser firing must use fire presentation"):
		return

	boss.phase = 3
	boss.state = GoldBarTank.State.CHASE
	boss._update_visual(0.0)
	if not _check(boss.visual_sprite.animation == &"damaged", "Phase three chase must use damaged presentation"):
		return

	boss.queue_free()
	print("PASS: Gold Bar Tank presentation follows attack state and damage phase")
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
