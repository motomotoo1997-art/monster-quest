extends SceneTree


func _init() -> void:
	var health := HealthComponent.new()
	health.max_health = 100.0
	root.add_child(health)
	health.reset_health()
	health.damage(25.0)
	assert(is_equal_approx(health.current_health, 75.0))
	health.heal(10.0)
	assert(is_equal_approx(health.current_health, 85.0))
	health.damage(-50.0)
	assert(is_equal_approx(health.current_health, 85.0), "Negative damage must be ignored")
	health.damage(500.0)
	assert(health.is_dead())
	assert(is_zero_approx(health.current_health))
	health.reset_health()
	assert(not health.is_dead())
	assert(is_equal_approx(health.current_health, 100.0))

	var player := TeamComponent.new()
	player.team = TeamComponent.Team.PLAYER
	var enemy := TeamComponent.new()
	enemy.team = TeamComponent.Team.ENEMY
	var neutral := TeamComponent.new()
	neutral.team = TeamComponent.Team.NEUTRAL
	assert(player.is_hostile_to(enemy))
	assert(enemy.is_hostile_to(player))
	assert(not player.is_hostile_to(player))
	assert(not player.is_hostile_to(neutral))

	health.queue_free()
	player.free()
	enemy.free()
	neutral.free()
	quit(0)
