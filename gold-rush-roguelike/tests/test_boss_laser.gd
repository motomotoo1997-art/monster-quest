extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var boss_scene := load("res://scenes/enemies/GoldBarTank.tscn") as PackedScene
	var player_scene := load("res://scenes/player/Prospector.tscn") as PackedScene
	if boss_scene == null or player_scene == null:
		_fail("Boss and Prospector scenes must load")
		return

	var boss := boss_scene.instantiate() as GoldBarTank
	var target := player_scene.instantiate() as Prospector
	if boss == null or target == null:
		_fail("Boss and Prospector scenes must instantiate")
		return

	root.add_child(boss)
	root.add_child(target)
	boss.global_position = Vector2(100.0,100.0)
	await process_frame
	# Keep the fixture on the actual cannon line. Art passes are allowed to move
	# the visual muzzle without silently invalidating the combat regression.
	var target_hurtbox := target.get_node("HurtboxComponent") as HurtboxComponent
	var hurtbox_local_y := target_hurtbox.position.y
	target.global_position = boss.muzzle.global_position + Vector2(180.0,-hurtbox_local_y)
	target.set_input_enabled(false)
	boss.set_targets(target,target)
	boss._charge_direction = Vector2.RIGHT

	await physics_frame
	await physics_frame

	var before := target.health_component.current_health
	boss._fire_laser()
	await process_frame
	var after := target.health_component.current_health

	if not is_equal_approx(before - after,boss.laser_damage):
		_fail("Boss laser must deal %.1f damage; before=%.1f after=%.1f" % [boss.laser_damage,before,after])
		return

	boss.queue_free()
	target.queue_free()
	print("PASS: Gold Bar Tank laser ray damages hostile Hurtbox from actual muzzle line")
	quit(0)


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
