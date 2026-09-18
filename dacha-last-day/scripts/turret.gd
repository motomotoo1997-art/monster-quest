extends Node2D

@export var fire_interval: float = 0.55
@export var range: float = 390.0
@export var damage: int = 16
var fire_clock := 0.0

const BULLET_SCENE := preload("res://scenes/bullet.tscn")

func _physics_process(delta: float) -> void:
	fire_clock = maxf(0.0, fire_clock - delta)
	var target := _nearest_enemy()
	if target == null:
		return
	$Barrel.rotation = global_position.direction_to(target.global_position).angle()
	if fire_clock <= 0.0:
		var bullet := BULLET_SCENE.instantiate()
		bullet.global_position = $Barrel/Muzzle.global_position
		bullet.rotation = $Barrel.rotation
		bullet.damage = damage
		bullet.collision_mask = 2
		get_tree().current_scene.add_child(bullet)
		fire_clock = fire_interval

func _nearest_enemy() -> Node2D:
	var best: Node2D
	var best_dist := range
	for node in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(node):
			continue
		var dist := global_position.distance_to(node.global_position)
		if dist < best_dist:
			best = node as Node2D
			best_dist = dist
	return best
