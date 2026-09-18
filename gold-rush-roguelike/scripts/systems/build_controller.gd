extends Node
class_name BuildController

signal selection_changed(slot: int)
signal preview_validity_changed(valid: bool)
signal defense_built(defense: DefenseBase)
signal defense_unlocked(slot: int)

@export var economy_path: NodePath
@export var defense_scenes: Array[PackedScene] = []
@export_flags_2d_physics var build_zone_mask: int = 16
@export_flags_2d_physics var blocking_mask: int = 1

var selected_slot: int = 0
var preview_instance: DefenseBase
var unlocked_slots: Array[int] = [2]
var _last_preview_valid := false
var economy: EconomyController


func _ready() -> void:
	add_to_group("build_controller")
	economy = _resolve_economy()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("build_1") or Input.is_action_just_pressed("ability_q"):
		select_defense(1)
		begin_preview()
	elif Input.is_action_just_pressed("build_2") or Input.is_action_just_pressed("ability_e"):
		select_defense(2)
		begin_preview()
	elif Input.is_action_just_pressed("build_3"):
		select_defense(3)
		begin_preview()
	elif Input.is_action_just_pressed("ability_r") and preview_instance == null:
		trigger_tnt()

	if preview_instance == null:
		return
	var world_position := _get_mouse_world_position()
	preview_instance.global_position = world_position
	var valid := _is_position_valid(world_position)
	preview_instance.modulate = Color(0.55, 1.0, 0.55, 0.58) if valid else Color(1.0, 0.38, 0.3, 0.58)
	if valid != _last_preview_valid:
		_last_preview_valid = valid
		preview_validity_changed.emit(valid)
	if Input.is_action_just_pressed("fire"):
		confirm_build(world_position)


func select_defense(slot: int) -> void:
	if slot < 1 or slot > defense_scenes.size() or not is_unlocked(slot):
		selected_slot = 0
		selection_changed.emit(selected_slot)
		return
	selected_slot = slot
	selection_changed.emit(selected_slot)


func unlock_defense(slot: int) -> void:
	if slot < 1 or slot > defense_scenes.size() or unlocked_slots.has(slot):
		return
	unlocked_slots.append(slot)
	unlocked_slots.sort()
	defense_unlocked.emit(slot)


func is_unlocked(slot: int) -> bool:
	return unlocked_slots.has(slot)


func begin_preview() -> void:
	cancel_build()
	var scene := _get_selected_scene()
	if scene == null:
		return
	var preview := scene.instantiate() as DefenseBase
	if preview == null:
		return
	var parent := get_tree().current_scene
	if parent == null:
		preview.free()
		return
	parent.add_child(preview)
	preview_instance = preview
	preview_instance.process_mode = Node.PROCESS_MODE_DISABLED
	_disable_collision_recursive(preview_instance)
	preview_instance.modulate = Color(1, 1, 1, 0.58)
	_last_preview_valid = false


func confirm_build(world_position: Vector2) -> bool:
	var scene := _get_selected_scene()
	if scene == null or economy == null or not _is_position_valid(world_position):
		return false
	var defense := scene.instantiate() as DefenseBase
	if defense == null:
		return false
	var cost := defense.get_build_cost()
	if not economy.can_afford(cost):
		defense.free()
		return false
	var parent := get_tree().current_scene
	if parent == null:
		defense.free()
		return false
	if not economy.spend_gold(cost):
		defense.free()
		return false
	parent.add_child(defense)
	defense.global_position = world_position
	defense_built.emit(defense)
	cancel_build()
	return true


func cancel_build() -> void:
	if preview_instance != null and is_instance_valid(preview_instance):
		preview_instance.queue_free()
	preview_instance = null
	_last_preview_valid = false


func trigger_tnt() -> void:
	if not is_unlocked(3):
		return
	for defense in get_tree().get_nodes_in_group("defenses"):
		if defense is TNTBarrel:
			(defense as TNTBarrel).trigger()


func _get_selected_scene() -> PackedScene:
	if selected_slot < 1 or selected_slot > defense_scenes.size() or not is_unlocked(selected_slot):
		return null
	return defense_scenes[selected_slot - 1]


func _is_position_valid(world_position: Vector2) -> bool:
	var space_state := get_viewport().world_2d.direct_space_state
	var zone_query := PhysicsPointQueryParameters2D.new()
	zone_query.position = world_position
	zone_query.collision_mask = build_zone_mask
	zone_query.collide_with_areas = true
	zone_query.collide_with_bodies = false
	var inside_build_zone := false
	for hit in space_state.intersect_point(zone_query, 32):
		var collider := hit.get("collider") as Node
		if collider != null and collider.is_in_group("build_zone"):
			inside_build_zone = true
			break
	if not inside_build_zone:
		return false

	var blocking_query := PhysicsPointQueryParameters2D.new()
	blocking_query.position = world_position
	blocking_query.collision_mask = blocking_mask
	blocking_query.collide_with_areas = false
	blocking_query.collide_with_bodies = true
	return space_state.intersect_point(blocking_query, 8).is_empty()


func _get_mouse_world_position() -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()


func _disable_collision_recursive(node: Node) -> void:
	if node is CollisionObject2D:
		var collision_object := node as CollisionObject2D
		collision_object.collision_layer = 0
		collision_object.collision_mask = 0
	for child in node.get_children():
		_disable_collision_recursive(child)


func _resolve_economy() -> EconomyController:
	if not economy_path.is_empty():
		return get_node_or_null(economy_path) as EconomyController
	return get_tree().get_first_node_in_group("economy_controller") as EconomyController
