extends Area2D
class_name MoltenPuddle

@export_range(0.2, 20.0, 0.1) var duration: float = 4.0
@export_range(0.05, 5.0, 0.05) var tick_interval: float = 0.5
@export_range(0.0, 1000.0, 0.5) var damage_per_tick: float = 6.0

var owner_team: TeamComponent.Team = TeamComponent.Team.ENEMY
var _remaining := 4.0
var _tick_remaining := 0.25


func _ready() -> void:
	_remaining = duration
	_tick_remaining = minf(tick_interval, 0.25)


func _physics_process(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		queue_free()
		return
	_tick_remaining -= delta
	if _tick_remaining > 0.0:
		return
	_tick_remaining = tick_interval
	for area in get_overlapping_areas():
		if area is HurtboxComponent:
			(area as HurtboxComponent).receive_hit(damage_per_tick, owner_team, Vector2.ZERO)


func configure(team: TeamComponent.Team, new_damage: float = -1.0) -> void:
	owner_team = team
	if new_damage >= 0.0:
		damage_per_tick = new_damage
