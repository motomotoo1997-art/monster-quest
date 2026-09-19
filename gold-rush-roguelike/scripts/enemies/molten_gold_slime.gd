extends EnemyBase
class_name MoltenGoldSlime

@export var puddle_scene: PackedScene
@export_range(0.2, 8.0, 0.1) var puddle_interval: float = 1.4
@export_range(0.0, 1000.0, 0.5) var puddle_damage: float = 5.0

var _puddle_cooldown_remaining := 0.35
var _shadow_base_scale := Vector2.ONE

@onready var ground_shadow: Polygon2D = $Shadow
@onready var molten_aura: Polygon2D = $MoltenAura
@onready var core_glow: Polygon2D = $CoreGlow


func _ready() -> void:
	super._ready()
	_shadow_base_scale = ground_shadow.scale


func _tick_behavior(delta: float) -> void:
	_puddle_cooldown_remaining = maxf(_puddle_cooldown_remaining - delta, 0.0)
	if _puddle_cooldown_remaining <= 0.0:
		_spawn_puddle()
		_puddle_cooldown_remaining = puddle_interval
	var target := choose_target()
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if global_position.distance_to(target.global_position) > attack_range:
		_move_toward(target.global_position, 0.72)
	else:
		velocity = _get_separation_force() * 0.25
		_try_contact_attack(target)
	move_and_slide()


func _update_visual(delta: float) -> void:
	if visual_sprite == null:
		return
	_visual_time += delta
	if absf(velocity.x) > 2.0:
		visual_sprite.flip_h = velocity.x < 0.0
	var moving := velocity.length() > 7.0
	var next_animation: StringName = &"move" if moving else &"idle"
	if visual_sprite.animation != next_animation:
		visual_sprite.play(next_animation)

	var wave := sin(_visual_time * 4.8)
	var secondary_wave := sin(_visual_time * 7.4 + 1.3)
	var move_factor := clampf(velocity.length() / maxf(move_speed, 1.0), 0.0, 1.0)
	visual_sprite.position = _visual_base_position + Vector2(secondary_wave * 1.1 * move_factor, wave * 1.8 - move_factor * 1.0)
	visual_sprite.scale = Vector2(
		_visual_base_scale.x * (1.0 + wave * 0.038 + move_factor * 0.018),
		_visual_base_scale.y * (1.0 - wave * 0.050 - move_factor * 0.010)
	)
	visual_sprite.rotation = secondary_wave * 0.018 * move_factor

	var pulse01 := (wave + 1.0) * 0.5
	molten_aura.scale = Vector2(0.95 + pulse01 * 0.10 + move_factor * 0.04, 0.90 + (1.0 - pulse01) * 0.10)
	molten_aura.rotation = sin(_visual_time * 2.1) * 0.035
	molten_aura.modulate = Color(1.0,1.0,1.0,0.62 + pulse01 * 0.30)
	core_glow.position = _visual_base_position + Vector2(0.0, 4.0 + wave * 1.4)
	core_glow.scale = Vector2.ONE * (0.82 + pulse01 * 0.23)
	core_glow.modulate = Color(1.0,1.0,1.0,0.62 + pulse01 * 0.34)
	ground_shadow.scale = _shadow_base_scale * Vector2(1.0 + wave * 0.04 + move_factor * 0.05, 1.0 - wave * 0.03)


func _spawn_puddle() -> void:
	if puddle_scene == null:
		return
	var puddle := puddle_scene.instantiate() as MoltenPuddle
	if puddle == null:
		return
	var target_parent := get_tree().current_scene
	if target_parent == null:
		target_parent = get_parent()
	if target_parent == null:
		puddle.free()
		return
	target_parent.add_child(puddle)
	puddle.global_position = global_position
	puddle.configure(team_component.team, puddle_damage)
