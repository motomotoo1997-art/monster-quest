extends Node
class_name TargetingComponent

@export var target_group: StringName = &"enemies"
@export_range(1.0, 2000.0, 1.0) var range: float = 320.0
@export var team_component_path: NodePath

var team_component: TeamComponent


func _ready() -> void:
	team_component = _resolve_team_component()


func get_nearest_hostile(origin: Vector2) -> Node2D:
	if team_component == null:
		return null
	var best: Node2D
	var best_distance_sq := range * range
	for candidate in get_tree().get_nodes_in_group(target_group):
		if not candidate is Node2D:
			continue
		var node := candidate as Node2D
		var target_team := node.get_node_or_null("TeamComponent") as TeamComponent
		if target_team == null or not team_component.is_hostile_to(target_team):
			continue
		var health := node.get_node_or_null("HealthComponent") as HealthComponent
		if health != null and health.is_dead():
			continue
		var distance_sq := origin.distance_squared_to(node.global_position)
		if distance_sq <= best_distance_sq:
			best_distance_sq = distance_sq
			best = node
	return best


func set_range(value: float) -> void:
	range = maxf(value, 1.0)


func _resolve_team_component() -> TeamComponent:
	if not team_component_path.is_empty():
		return get_node_or_null(team_component_path) as TeamComponent
	var parent := get_parent()
	if parent == null:
		return null
	return parent.get_node_or_null("TeamComponent") as TeamComponent
