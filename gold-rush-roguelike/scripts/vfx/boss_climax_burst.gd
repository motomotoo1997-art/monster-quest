extends Node2D
class_name BossClimaxBurstVFX

@export_range(0.2, 3.0, 0.05) var duration: float = 0.92
@export_range(40.0, 240.0, 1.0) var shard_distance: float = 132.0

var _age: float = 0.0
var _base_positions: Array[Vector2] = []
var _directions: Array[Vector2] = []

@onready var core_flash: PointLight2D = $CoreFlash
@onready var shock_ring: Line2D = $ShockRing
@onready var cyan_ring: Line2D = $CyanRing
@onready var core_burst: Polygon2D = $CoreBurst
@onready var gold_shards: Node2D = $GoldShards
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
	shock_ring.scale = Vector2.ONE * 0.32
	cyan_ring.scale = Vector2.ONE * 0.18
	core_burst.scale = Vector2.ONE * 0.78
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
		var distance_scale: float = 0.82 + 0.035 * float(index)
		shard.position = _base_positions[index] + _directions[index] * shard_distance * distance_scale * eased
		var spin_sign: float = 1.0 if index % 2 == 0 else -1.0
		shard.rotation = spin_sign * t * (2.1 + float(index) * 0.11)
		var shard_color: Color = shard.modulate
		shard_color.a = 1.0 - t
		shard.modulate = shard_color

	shock_ring.scale = Vector2.ONE * lerpf(0.32, 3.3, eased)
	cyan_ring.scale = Vector2.ONE * lerpf(0.18, 2.55, eased)
	shock_ring.rotation += delta * 0.45
	cyan_ring.rotation -= delta * 0.82
	var ring_alpha: float = 1.0 - t
	var shock_color: Color = shock_ring.modulate
	shock_color.a = ring_alpha
	shock_ring.modulate = shock_color
	var cyan_color: Color = cyan_ring.modulate
	cyan_color.a = ring_alpha * 0.92
	cyan_ring.modulate = cyan_color

	core_burst.scale = Vector2.ONE * lerpf(0.78, 2.35, eased)
	var core_color: Color = core_burst.modulate
	core_color.a = 1.0 - t
	core_burst.modulate = core_color
	core_flash.energy = lerpf(3.65, 0.0, t)
	core_flash.texture_scale = lerpf(1.25, 2.35, eased)

	if t >= 1.0:
		queue_free()
