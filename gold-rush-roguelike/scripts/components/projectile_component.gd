extends Area2D
class_name ProjectileComponent

@export_range(1.0, 5000.0, 1.0) var speed: float = 900.0
@export_range(0.0, 100000.0, 0.5) var damage: float = 10.0
@export_range(0.05, 30.0, 0.05) var lifetime: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var owner_team: TeamComponent.Team = TeamComponent.Team.NEUTRAL
var _remaining_lifetime: float = 2.0
var _configured := false


func _ready() -> void:
	_remaining_lifetime = lifetime
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not _configured:
		return
	global_position += direction * speed * delta
	_remaining_lifetime -= delta
	if _remaining_lifetime <= 0.0:
		queue_free()


func configure(
	new_direction: Vector2,
	new_speed: float,
	new_damage: float,
	new_owner_team: TeamComponent.Team
) -> void:
	direction = new_direction.normalized()
	speed = maxf(new_speed, 0.0)
	damage = maxf(new_damage, 0.0)
	owner_team = new_owner_team
	_remaining_lifetime = lifetime
	_configured = not direction.is_zero_approx()
	rotation = direction.angle()


func _on_area_entered(area: Area2D) -> void:
	if not area is HurtboxComponent:
		return
	var hurtbox := area as HurtboxComponent
	var knockback := direction * minf(speed * 0.08, 160.0)
	if hurtbox.receive_hit(damage, owner_team, knockback):
		queue_free()


func _on_body_entered(_body: Node2D) -> void:
	queue_free()
