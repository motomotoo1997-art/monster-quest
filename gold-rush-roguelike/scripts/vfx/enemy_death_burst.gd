extends Node2D

@export_range(0.1, 2.0, 0.01) var duration: float = 0.46
@export_range(10.0, 120.0, 1.0) var shard_distance: float = 58.0

var _age: float = 0.0
var _base_positions: Array[Vector2] = []
var _directions: Array[Vector2] = []
var _start_light_energy: float = 2.15

@onready var gold_shards: Node2D = $GoldShards
@onready var shock_ring: Line2D = $ShockRing
@onready var echo_ring: Line2D = $EchoRing
@onready var core_burst: Polygon2D = $CoreBurst
@onready var death_light: PointLight2D = $DeathLight
@onready var dust: CPUParticles2D = $Dust


func _ready() -> void:
	_start_light_energy = death_light.energy
	var shard_count: int = gold_shards.get_child_count()
	for index in range(shard_count):
		var shard: Node2D = gold_shards.get_child(index) as Node2D
		if shard == null:
			continue
		_base_positions.append(shard.position)
		var angle: float = TAU * float(index) / float(maxi(shard_count, 1)) - PI * 0.5
		_directions.append(Vector2.from_angle(angle))
	shock_ring.scale = Vector2.ONE * 0.34
	echo_ring.scale = Vector2.ONE * 0.22
	echo_ring.modulate.a = 0.82
	core_burst.scale = Vector2.ONE * 0.72
	dust.restart()


func configure_elite_variant() -> void:
	# Elite deaths get one stronger cyan/gold punctuation layer, but no camera shake.
	# The scale bump stays compact enough that dense Arena04 fights remain readable.
	scale = Vector2.ONE * 1.24
	_start_light_energy = 2.80
	death_light.energy = _start_light_energy
	core_burst.color = Color(1.0, 0.86, 0.32, 1.0)
	echo_ring.width = 3.4
	dust.amount = 20


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

	# The warm echo starts a fraction later than the cyan ring. This gives deaths
	# a two-stage snap without growing the effect enough to hide nearby enemies.
	var echo_t: float = clampf((t - 0.10) / 0.90, 0.0, 1.0)
	var echo_eased: float = 1.0 - float(pow(1.0 - echo_t, 2.0))
	echo_ring.scale = Vector2.ONE * lerpf(0.22, 2.58, echo_eased)
	var echo_color: Color = echo_ring.modulate
	echo_color.a = (1.0 - echo_t) * 0.82
	echo_ring.modulate = echo_color

	core_burst.scale = Vector2.ONE * lerpf(0.72, 1.72, eased)
	var core_color: Color = core_burst.modulate
	core_color.a = 1.0 - t
	core_burst.modulate = core_color
	death_light.energy = lerpf(_start_light_energy, 0.0, t)

	if t >= 1.0:
		queue_free()
