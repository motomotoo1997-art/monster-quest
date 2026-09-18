extends Area2D
class_name HitboxComponent

@export_range(0.0, 100000.0, 0.5) var damage: float = 10.0
@export_range(0.0, 5000.0, 1.0) var knockback_strength: float = 0.0
@export var team_component_path: NodePath
@export var one_shot := false

var team_component: TeamComponent
var _consumed := false


func _ready() -> void:
	team_component = _resolve_team_component()
	area_entered.connect(_on_area_entered)


func set_damage(value: float) -> void:
	damage = maxf(value, 0.0)


func _on_area_entered(area: Area2D) -> void:
	if _consumed and one_shot:
		return
	if not area is HurtboxComponent or team_component == null:
		return
	var hurtbox := area as HurtboxComponent
	var direction := global_position.direction_to(hurtbox.global_position)
	var applied := hurtbox.receive_hit(
		damage,
		team_component.team,
		direction * knockback_strength
	)
	if applied and one_shot:
		_consumed = true


func _resolve_team_component() -> TeamComponent:
	if not team_component_path.is_empty():
		return get_node_or_null(team_component_path) as TeamComponent
	var parent := get_parent()
	if parent == null:
		return null
	return parent.get_node_or_null("TeamComponent") as TeamComponent
