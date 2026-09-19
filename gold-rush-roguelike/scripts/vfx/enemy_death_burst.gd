extends Node2D

@export_range(0.1, 2.0, 0.01) var duration: float = 0.46
@export_range(10.0, 120.0, 1.0) var shard_distance: float = 58.0

var _age: float = 0.0
var _base_positions: Array[Vector2] = []
var _directions: Array[Vector2] = []

@onready var gold_shards: Node2D = $GoldShards
@onready var shock_ring: Line2D = $ShockRing
@onready var core_burst: Polygon2D = $CoreBurst
@onready var death_light: PointLight2D = $DeathLight
@onready var dust: CPUParticles2D = $Dust


func _ready() -> void:
	var shard_count: int = gold_shards.get_child_count()
	for index in range(shard_count):
		var shard: Node2D = gold_shards.get_child(index) as Node2D
		if shard == null:
			continue
		_base_positions.append(shard.position)
		var angle: float = TAU * float(index) / float(maxi(shard_count, 1)) - PI * 0.5
		_directions.append(Vector2.from_angle(angle))
	shock_ring.scale = Vector2.ONE * 0.34
	core_burst.scale = Vector2.ONE * 0.72
	dust.restart()


func _process(delta: float) -> void:
	_age += delta
	var t: float = clampf(_age / maxf(duration, 0.001), 0.0, 1.0)
	var eased: float = 1.0 - float(pow(1.0 - t, 3.0))
	var usable_count: int = mini(gold_shards.get_child_count(), _directions.size())
	for index in range(usable_count):
		var shard: Node2D = gold_shards.get_child(index) as Node2D
		if shard == null:
			continue
		shard.position = _base_positions[index] + _directions[index] * shard_distance * eased
		var spin_sign: float = 1.0 if index % 2 == 0 else -1.0
		shard.rotation = spin_sign * t * (1.2 + float(index) * 0.16)
		var shard_color: Color = shard.modulate
		shard_color.a = 1.0 - t
		shard.modulate = shard_color

	shock_ring.scale = Vector2.ONE * lerpf(0.34, 2.05, eased)
	var ring_color: Color = shock_ring.modulate
	ring_color.a = 1.0 - t
	shock_ring.modulate = ring_color
	core_burst.scale = Vector2.ONE * lerpf(0.72, 1.72, eased)
	var core_color: Color = core_burst.modulate
	core_color.a = 1.0 - t
	core_burst.modulate = core_color
	death_light.energy = lerpf(2.15, 0.0, t)

	if t >= 1.0:
		queue_free()
