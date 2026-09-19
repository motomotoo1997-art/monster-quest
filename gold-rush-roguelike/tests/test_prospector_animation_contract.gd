extends SceneTree

const REQUIRED_ANIMATIONS := {
	&"idle": 3,
	&"move": 4,
	&"attack": 4,
	&"hit": 2,
	&"dash": 3,
	&"death": 4,
}

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var packed := load("res://scenes/player/Prospector.tscn") as PackedScene
	if packed == null:
		_fail("Prospector scene must load")
		return
	var player := packed.instantiate()
	root.add_child(player)
	await process_frame
	var sprite := player.get_node_or_null("BodyVisual") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		_fail("Prospector BodyVisual must use AnimatedSprite2D with SpriteFrames")
		return
	var frames := sprite.sprite_frames
	for animation_name in REQUIRED_ANIMATIONS:
		if not frames.has_animation(animation_name):
			_fail("Prospector animation missing: %s" % animation_name)
			return
		var frame_count := frames.get_frame_count(animation_name)
		if frame_count < int(REQUIRED_ANIMATIONS[animation_name]):
			_fail("Prospector %s needs at least %d frames, found %d" % [animation_name, REQUIRED_ANIMATIONS[animation_name], frame_count])
			return
		if frames.get_animation_speed(animation_name) < 5.0:
			_fail("Prospector animation FPS too low: %s" % animation_name)
			return
	print("PASS: Prospector has production multi-frame idle/move/attack/hit/dash/death animations")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
