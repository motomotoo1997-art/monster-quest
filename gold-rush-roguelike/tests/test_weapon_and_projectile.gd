extends SceneTree


func _init() -> void:
	var weapon := WeaponComponent.new()
	weapon.cooldown_sec = 0.25
	root.add_child(weapon)
	assert(weapon.can_fire())
	weapon.mark_fired()
	assert(not weapon.can_fire())

	var projectile := ProjectileComponent.new()
	root.add_child(projectile)
	projectile.configure(Vector2.RIGHT, 500.0, 17.0, TeamComponent.Team.PLAYER)
	assert(projectile.direction == Vector2.RIGHT)
	assert(is_equal_approx(projectile.speed, 500.0))
	assert(is_equal_approx(projectile.damage, 17.0))
	assert(projectile.owner_team == TeamComponent.Team.PLAYER)

	weapon.queue_free()
	projectile.queue_free()
	quit(0)
