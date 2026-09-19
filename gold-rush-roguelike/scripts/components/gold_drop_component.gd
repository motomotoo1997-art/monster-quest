extends Node
class_name GoldDropComponent

@export_range(1, 10000, 1) var gold_amount: int = 5
@export var pickup_scene: PackedScene


func _ready() -> void:
	var owner_node := get_parent()
	if owner_node == null:
		return
	var health := owner_node.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.died.connect(_on_owner_died)


func spawn_drop(world_position: Vector2) -> GoldPickup:
	if pickup_scene == null:
		return null
	var pickup := pickup_scene.instantiate() as GoldPickup
	if pickup == null:
		return null
	var target_parent := get_tree().current_scene
	if target_parent == null:
		target_parent = get_parent().get_parent()
	if target_parent == null:
		pickup.free()
		return null

	# A death can be emitted from Area2D.area_entered while PhysicsServer2D is flushing
	# queries. Adding the pickup immediately would enable its collision shape during that
	# flush and trigger a Godot physics error. Configure it now, but insert it next idle turn.
	pickup.position = world_position
	pickup.configure(gold_amount)
	target_parent.add_child.call_deferred(pickup)
	return pickup


func _on_owner_died() -> void:
	var owner_node := get_parent() as Node2D
	if owner_node != null:
		spawn_drop(owner_node.global_position)
