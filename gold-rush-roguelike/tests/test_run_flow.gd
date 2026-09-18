extends SceneTree


func _init() -> void:
	var enemy := EnemyBase.new()
	enemy.prefer_core_weight = 1.0
	var player := Node2D.new()
	var core := Node2D.new()
	player.position = Vector2(40, 0)
	core.position = Vector2(100, 0)
	enemy.set_targets(player, core)
	assert(enemy.choose_target() == core, "Core-biased enemy must prefer the core")
	player.free()
	assert(enemy.choose_target() == core, "Enemy must fall back to the surviving core target")
	core.free()
	assert(enemy.choose_target() == null, "Enemy must return null when no valid target remains")
	enemy.free()
	quit(0)
