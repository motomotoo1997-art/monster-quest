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

	var boss_texture := boss.visual_sprite.sprite_frames.get_frame_texture(&"idle", 0)
	if not _check(boss_texture is AtlasTexture, "Gold Bar Tank presentation must be atlas-backed"):
		return
	var boss_atlas := (boss_texture as AtlasTexture).atlas
	if not _check(boss_atlas != null and boss_atlas.resource_path.ends_with("boss_frontier_juggernaut_v6.svg"), "Boss must use the replacement Frontier Juggernaut atlas"):
		return
	if not _check(boss.visual_sprite.sprite_frames.has_animation(&"death"), "Gold Bar Tank must expose a disintegration death presentation"):
		return
	var disintegration_vfx := boss.get_node_or_null("DisintegrationVFX") as Node2D
	if not _check(disintegration_vfx != null, "Gold Bar Tank must include authored disintegration VFX"):
		return

	var warning_line := boss.get_node_or_null("ChargeTelegraph/WarningLine") as Line2D
	if not _check(warning_line != null and warning_line.width <= 6.0, "Boss laser warning must be a thin readable line, not a giant wedge"):
		return
	var beam_core := boss.get_node_or_null("ChargeTelegraph/BeamCore") as Line2D
	if not _check(beam_core != null and beam_core.width >= 8.0, "Boss firing beam needs a clean bright Line2D core"):
		return
	var boss_projectile_scene := boss.weapon_component.projectile_scene
	if not _check(boss_projectile_scene != null and boss_projectile_scene.resource_path.ends_with("BossProjectile.tscn"), "Boss burst must use dedicated boss projectiles"):
		return

	var charge_light := boss.get_node_or_null("ChargeTelegraph/ChargeLight") as PointLight2D
	if not _check(charge_light != null, "Laser telegraph must include a local PointLight2D"):
		return
	if not _check(charge_light.texture != null, "Laser telegraph light must use radial falloff"):
		return
	var slam_light := boss.get_node_or_null("SlamTelegraph/SlamLight") as PointLight2D
	if not _check(slam_light != null, "Slam telegraph must include a local PointLight2D"):
		return
	if not _check(slam_light.texture != null, "Slam telegraph light must use radial falloff"):
		return

	boss.phase = 1
	boss.state = GoldBarTank.State.CHASE
	boss._update_visual(0.0)
	if not _check(boss.visual_sprite.animation == &"idle", "CHASE must use idle presentation"):
		return

	boss.state = GoldBarTank.State.CHARGE_TELEGRAPH
	boss.charge_telegraph.visible = true
	boss._update_visual(0.1)
	if not _check(boss.visual_sprite.animation == &"charge", "Laser telegraph must use charge presentation"):
		return
	if not _check(charge_light.energy >= 1.2, "Laser telegraph light must be bright enough to warn the player"):
		return

	boss.state = GoldBarTank.State.CHARGE
	boss._update_visual(0.0)
	if not _check(boss.visual_sprite.animation == &"fire", "Laser firing must use fire presentation"):
		return

	boss.state = GoldBarTank.State.SLAM
	boss.slam_telegraph.visible = true
	boss._update_visual(0.1)
	if not _check(slam_light.energy >= 1.0, "Slam warning light must be readable against the desert floor"):
		return

	boss.phase = 3
	boss.state = GoldBarTank.State.CHASE
	boss._update_visual(0.0)
	if not _check(boss.visual_sprite.animation == &"damaged", "Phase three chase must use damaged presentation"):
		return

	boss.queue_free()
	print("PASS: Gold Bar Tank presentation follows attack state, telegraph lighting and damage phase")
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
