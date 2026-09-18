extends EnemyBase
class_name MoltenGoldSlime

@export var puddle_scene: PackedScene
@export_range(0.2, 8.0, 0.1) var puddle_interval: float = 1.4
@export_range(0.0, 1000.0, 0.5) var puddle_damage: float = 5.0

var _puddle_cooldown_remaining := 0.35


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
