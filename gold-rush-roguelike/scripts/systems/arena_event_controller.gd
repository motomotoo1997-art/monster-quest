extends Node
class_name ArenaEventController

signal event_started(event_id: StringName)
signal event_stopped(event_id: StringName)
signal hazard_impacted(world_position: Vector2, event_id: StringName)

@export var arena_controller_path: NodePath
@export var explosion_scene: PackedScene

var active_event_id: StringName = &""
var _active_config: Dictionary = {}
var _event_timer := 0.0
var _pattern_index := 0
var _pending_strikes: Array[Dictionary] = []

@onready var arena_controller: ArenaController = get_node_or_null(arena_controller_path) as ArenaController

func _process(delta: float) -> void:
	if active_event_id == &"":
		return
	_resolve_arena_controller()
	if arena_controller == null or arena_controller.current_arena == null:
		stop_event()
		return
	# A loading hitch must never consume the whole warning window in one frame.
	# Clamp hazard time advancement so every strike remains dodgeable and readable.
	var safe_delta := minf(delta,0.10)
	_event_timer = maxf(_event_timer - safe_delta,0.0)
	if _event_timer <= 0.0:
		_spawn_pattern()
		_event_timer = float(_active_config.get("interval",3.2))
	_tick_pending_strikes(safe_delta)

func get_event_config(arena_index: int, wave_number: int) -> Dictionary:
	if arena_index == 3 and wave_number == 2:
		return {
			"id": &"dynamite_rain",
			"interval": 3.4,
			"telegraph": 0.82,
			"damage": 12.0,
			"radius": 54.0,
			"strikes": 2,
		}
	if arena_index == 4 and wave_number == 1:
		return {
			"id": &"molten_burst",
			"interval": 3.25,
			"telegraph": 0.78,
			"damage": 13.0,
			"radius": 58.0,
			"strikes": 2,
		}
	if arena_index == 4 and wave_number == 3:
		return {
			"id": &"molten_burst",
			"interval": 2.55,
			"telegraph": 0.68,
			"damage": 15.0,
			"radius": 62.0,
			"strikes": 3,
		}
	return {}

func get_active_telegraph_count() -> int:
	var count := 0
	for strike in _pending_strikes:
		var telegraph := strike.get("telegraph") as Node
		if telegraph != null and is_instance_valid(telegraph) and telegraph.is_inside_tree():
			count += 1
	return count

func start_wave_event(arena_index: int, wave_number: int) -> void:
	stop_event()
	_resolve_arena_controller()
	_active_config = get_event_config(arena_index,wave_number)
	if _active_config.is_empty():
		return
	active_event_id = StringName(_active_config.get("id",&""))
	_event_timer = float(_active_config.get("interval",3.2))
	_pattern_index = 0
	_spawn_pattern()
	event_started.emit(active_event_id)

func stop_event() -> void:
	var stopped_id := active_event_id
	active_event_id = &""
	_active_config.clear()
	_event_timer = 0.0
	_pattern_index = 0
	for strike in _pending_strikes:
		var telegraph := strike.get("telegraph") as Node
		if telegraph != null and is_instance_valid(telegraph):
			telegraph.queue_free()
	_pending_strikes.clear()
	if stopped_id != &"":
		event_stopped.emit(stopped_id)

func _spawn_pattern() -> void:
	if _active_config.is_empty() or arena_controller == null or arena_controller.current_arena == null:
		return
	var strikes := maxi(int(_active_config.get("strikes",1)),1)
	var player := _resolve_player()
	var center := player.global_position if player != null else Vector2(720,360)
	for i in range(strikes):
		var offset := _pattern_offset(_pattern_index + i,strikes)
		_queue_strike(center + offset)
	_pattern_index += strikes

func _pattern_offset(index: int, strike_count: int) -> Vector2:
	var angle := float(index) * 2.39996323 + float(strike_count) * 0.37
	var radius := 44.0 + float(index % 3) * 32.0
	if index % max(strike_count,1) == 0:
		radius *= 0.35
	return Vector2.RIGHT.rotated(angle) * radius

func _queue_strike(world_position: Vector2) -> void:
	var radius := float(_active_config.get("radius",56.0))
	var telegraph := _create_telegraph(world_position,radius)
	_pending_strikes.append({
		"time": float(_active_config.get("telegraph",0.8)),
		"position": world_position,
		"radius": radius,
		"damage": float(_active_config.get("damage",12.0)),
		"telegraph": telegraph,
	})

func _create_telegraph(world_position: Vector2, radius: float) -> Node2D:
	var root_node := Node2D.new()
	root_node.name = "ArenaHazardTelegraph"
	root_node.position = world_position
	root_node.z_index = 8

	var fill := Polygon2D.new()
	fill.name = "DangerFill"
	var points := PackedVector2Array()
	for i in range(20):
		points.append(Vector2.RIGHT.rotated(TAU * float(i) / 20.0) * radius)
	fill.polygon = points
	fill.color = Color(1.0,0.18,0.04,0.12) if active_event_id == &"dynamite_rain" else Color(1.0,0.55,0.04,0.16)
	root_node.add_child(fill)

	var ring := Line2D.new()
	ring.name = "DangerRing"
	ring.width = 4.0
	ring.closed = true
	ring.antialiased = true
	ring.default_color = Color(1.0,0.31,0.08,0.95) if active_event_id == &"dynamite_rain" else Color(1.0,0.76,0.16,0.96)
	for i in range(28):
		ring.add_point(Vector2.RIGHT.rotated(TAU * float(i) / 28.0) * radius)
	root_node.add_child(ring)

	var cross := Line2D.new()
	cross.name = "WarningCross"
	cross.width = 3.0
	cross.default_color = Color(1.0,0.92,0.62,0.92)
	cross.add_point(Vector2(-radius * 0.55,0))
	cross.add_point(Vector2(radius * 0.55,0))
	root_node.add_child(cross)

	arena_controller.current_arena.add_child(root_node)
	root_node.add_to_group("arena_hazard_telegraph")
	root_node.global_position = world_position
	return root_node

func _tick_pending_strikes(delta: float) -> void:
	var survivors: Array[Dictionary] = []
	for strike in _pending_strikes:
		var remaining := float(strike.get("time",0.0)) - delta
		var telegraph := strike.get("telegraph") as Node2D
		if telegraph != null and is_instance_valid(telegraph):
			var duration := maxf(float(_active_config.get("telegraph",0.8)),0.01)
			var progress := 1.0 - clampf(remaining / duration,0.0,1.0)
			var pulse := 1.0 + sin(progress * PI * 6.0) * 0.055
			telegraph.scale = Vector2.ONE * pulse
			telegraph.modulate.a = 0.68 + progress * 0.32
		if remaining <= 0.0:
			_impact_strike(strike)
		else:
			strike["time"] = remaining
			survivors.append(strike)
	_pending_strikes = survivors

func _impact_strike(strike: Dictionary) -> void:
	var world_position: Vector2 = strike.get("position",Vector2.ZERO)
	var radius := float(strike.get("radius",56.0))
	var damage := float(strike.get("damage",12.0))
	var telegraph := strike.get("telegraph") as Node
	if telegraph != null and is_instance_valid(telegraph):
		telegraph.queue_free()

	var player := _resolve_player()
	if player != null and player.global_position.distance_to(world_position) <= radius:
		var hurtbox := player.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hurtbox != null:
			var knockback := world_position.direction_to(player.global_position) * 130.0
			hurtbox.receive_hit(damage,TeamComponent.Team.ENEMY,knockback)

	if explosion_scene != null and arena_controller != null and arena_controller.current_arena != null:
		var explosion := explosion_scene.instantiate() as Node2D
		if explosion != null:
			arena_controller.current_arena.add_child(explosion)
			explosion.global_position = world_position
			if active_event_id == &"molten_burst":
				explosion.modulate = Color(1.0,0.72,0.38,1.0)
	hazard_impacted.emit(world_position,active_event_id)

func _resolve_arena_controller() -> void:
	if arena_controller != null and is_instance_valid(arena_controller):
		return
	arena_controller = get_node_or_null(arena_controller_path) as ArenaController
	if arena_controller == null and get_parent() != null:
		arena_controller = get_parent().get_node_or_null("ArenaController") as ArenaController

func _resolve_player() -> Prospector:
	if arena_controller == null or arena_controller.current_arena == null:
		return null
	return arena_controller.current_arena.find_child("Prospector",true,false) as Prospector
