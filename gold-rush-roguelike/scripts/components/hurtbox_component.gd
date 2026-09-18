extends Area2D
class_name HurtboxComponent

signal hit_received(damage: float)
signal knockback_requested(force: Vector2)

@export var health_component_path: NodePath
@export var team_component_path: NodePath

var health_component: HealthComponent
var team_component: TeamComponent


func _ready() -> void:
	health_component = _resolve_health_component()
	team_component = _resolve_team_component()


func receive_hit(
	damage: float,
	source_team: TeamComponent.Team,
	knockback: Vector2 = Vector2.ZERO
) -> bool:
	if damage <= 0.0 or health_component == null or team_component == null:
		return false
	if not team_component.is_hostile_team(source_team):
		return false
	health_component.damage(damage)
	hit_received.emit(damage)
	if knockback != Vector2.ZERO:
		knockback_requested.emit(knockback)
	return true


func _resolve_health_component() -> HealthComponent:
	if not health_component_path.is_empty():
		return get_node_or_null(health_component_path) as HealthComponent
	var parent := get_parent()
	if parent == null:
		return null
	return parent.get_node_or_null("HealthComponent") as HealthComponent


func _resolve_team_component() -> TeamComponent:
	if not team_component_path.is_empty():
		return get_node_or_null(team_component_path) as TeamComponent
	var parent := get_parent()
	if parent == null:
		return null
	return parent.get_node_or_null("TeamComponent") as TeamComponent
