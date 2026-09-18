extends RefCounted

const FRAME_SIZE := 192
const COLUMNS := 4
const DIRECTIONS := 8

static func build_directional_frames(atlas: Texture2D, prefix: String = "move", fps: float = 8.0) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for row in DIRECTIONS:
		var animation_name := StringName("%s_%d" % [prefix, row])
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, true)
		frames.set_animation_speed(animation_name, fps)
		for column in COLUMNS:
			var frame := AtlasTexture.new()
			frame.atlas = atlas
			frame.region = Rect2(column * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(animation_name, frame)
	return frames

static func direction_index(direction: Vector2) -> int:
	if direction.length_squared() < 0.0001:
		return 4
	var octant := int(round((direction.angle() + PI * 0.5) / (PI * 0.25)))
	return posmod(octant, DIRECTIONS)
