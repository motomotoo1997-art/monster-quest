extends SceneTree


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var enemy_scene := load("res://scenes/enemies/GoldHopper.tscn") as PackedScene
	if enemy_scene == null:
		_fail("GoldHopper scene must load")
		return
	var enemy := enemy_scene.instantiate() as EnemyBase
	if enemy == null:
		_fail("GoldHopper scene must instantiate as EnemyBase")
		return
	root.add_child(enemy)
	await process_frame

	if not enemy.has_method("is_alive"):
		_fail("EnemyBase must expose is_alive() for WaveDirector pruning")
		return
	if not enemy.is_alive():
		_fail("Fresh enemy must report alive")
		return

	var director := WaveDirector.new()
	root.add_child(director)
	director._active_enemies.append(enemy)
	if director.get_alive_enemy_count() != 1:
		_fail("WaveDirector must retain one living enemy")
		return

	enemy.health_component.damage(enemy.health_component.max_health)
	await process_frame
	if director.get_alive_enemy_count() != 0:
		_fail("WaveDirector must remove a dead/freed enemy")
		return

	director.queue_free()
	print("PASS: WaveDirector prunes enemies through explicit alive contract")
	quit(0)


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
