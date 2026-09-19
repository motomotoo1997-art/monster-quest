extends SceneTree

const V6_ATLAS := "res://assets/vfx/combat_feedback_v6.svg"

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var player_shot := await _spawn("res://scenes/combat/Projectile.tscn")
	if player_shot == null:
		return
	if player_shot.find_children("*","PointLight2D",true,false).size() != 0:
		_fail("Normal player projectiles must avoid per-shot PointLight2D")
		return
	if not _check_v6_sprite(player_shot,"V6Bolt"):
		return
	player_shot.queue_free()
	await process_frame

	var boss_shot := await _spawn("res://scenes/combat/BossProjectile.tscn")
	if boss_shot == null:
		return
	if boss_shot.get_node_or_null("ShotLight") == null or not _check_v6_sprite(boss_shot,"V6Bolt"):
		_fail("Boss projectile needs a dedicated v6 bolt plus meaningful local light")
		return
	boss_shot.queue_free()
	await process_frame

	var hit := await _spawn("res://scenes/vfx/HitFlash.tscn")
	if hit == null or not _check_v6_sprite(hit,"V6Impact"):
		return
	await create_timer(0.28).timeout
	if is_instance_valid(hit):
		_fail("HitFlash must self-clean after its short impact lifetime")
		return

	var explosion := await _spawn("res://scenes/vfx/Explosion.tscn")
	if explosion == null or not _check_v6_sprite(explosion,"V6Explosion"):
		return
	await create_timer(0.58).timeout
	if is_instance_valid(explosion):
		_fail("Explosion must self-clean after its authored lifetime")
		return

	var pickup := await _spawn("res://scenes/combat/GoldPickup.tscn")
	if pickup == null or not _check_v6_sprite(pickup,"Visual/V6Pickup"):
		return
	if pickup.get_node_or_null("LootLight") == null:
		_fail("Gold pickup needs its readable attraction light")
		return
	pickup.queue_free()
	await process_frame

	var hud := await _spawn("res://scenes/ui/HUD.tscn")
	if hud == null:
		return
	var boss_panel := hud.get_node_or_null("Root/BossPanel") as PanelContainer
	var boss_name := hud.get_node_or_null("Root/BossPanel/VBox/Name") as Label
	if boss_panel == null or boss_name == null or boss_name.text != "FRONTIER JUGGERNAUT":
		_fail("HUD needs a framed boss panel named FRONTIER JUGGERNAUT")
		return
	var player_bar := hud.get_node("Root/TopLeft/PlayerHP") as ProgressBar
	var core_bar := hud.get_node("Root/TopLeft/CoreHP") as ProgressBar
	var player_fill := player_bar.get_theme_stylebox("fill") as StyleBoxFlat
	var core_fill := core_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if player_fill == null or core_fill == null or player_fill.bg_color.is_equal_approx(core_fill.bg_color):
		_fail("HUD player and Gold Core bars must remain visually distinct")
		return
	hud.queue_free()
	await process_frame

	var upgrades := await _spawn("res://scenes/ui/UpgradeOverlay.tscn")
	if upgrades == null:
		return
	var card := upgrades.get_node_or_null("Root/Panel/Margin/VBox/Cards/Card1") as Button
	var normal := card.get_theme_stylebox("normal") as StyleBoxFlat if card != null else null
	if normal == null or normal.border_width_left < 2 or normal.bg_color.a < 0.9:
		_fail("Upgrade cards need solid western metal/leather framing")
		return
	upgrades.queue_free()
	print("PASS: v6 combat feedback is distinct, self-cleaning and aligned with the frontier HUD")
	quit(0)

func _spawn(path: String) -> Node:
	var packed := load(path) as PackedScene
	if packed == null:
		_fail("Scene must load: %s" % path)
		return null
	var node := packed.instantiate()
	root.add_child(node)
	await process_frame
	return node

func _check_v6_sprite(owner: Node, path: String) -> bool:
	var sprite := owner.get_node_or_null(path) as Sprite2D
	if sprite == null or sprite.texture == null:
		_fail("V6 feedback sprite missing: %s/%s" % [owner.name,path])
		return false
	var texture := sprite.texture
	if texture is AtlasTexture:
		texture = (texture as AtlasTexture).atlas
	if texture == null or texture.resource_path != V6_ATLAS:
		_fail("Feedback sprite must use combat_feedback_v6.svg: %s/%s" % [owner.name,path])
		return false
	return true

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
