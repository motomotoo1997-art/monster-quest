extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var packed := load("res://scenes/player/Prospector.tscn") as PackedScene
	if packed == null:
		_fail("Prospector scene must load")
		return
	var player := packed.instantiate() as Prospector
	root.add_child(player)
	await process_frame
	player.set_input_enabled(false)
	var sprite := player.body_visual
	var base_position := sprite.position
	var base_scale := sprite.scale
	for _i in range(12):
		player._update_body_visual(Vector2.ZERO, 0.1)
	if sprite.position.distance_to(base_position) > 0.01:
		_fail("Prospector idle must be visually stationary; BodyVisual position drifted")
		return
	if sprite.scale.distance_to(base_scale) > 0.001:
		_fail("Prospector idle must not breathe/squash while no input is pressed")
		return
	player._attack_pose_remaining = player.attack_pose_hold
	player._update_body_visual(Vector2.ZERO, 0.05)
	if sprite.position.distance_to(base_position) > 0.01 or sprite.scale.distance_to(base_scale) > 0.001:
		_fail("Prospector firing pose must keep the body anchored and use sprite recoil only")
		return
	if sprite.animation != &"attack":
		_fail("Prospector firing must switch to attack animation")
		return
	player.queue_free()
	print("PASS: Prospector idle is stationary and firing pose stays anchored")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
