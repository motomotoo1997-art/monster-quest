extends StaticBody2D
class_name DefenseBase

signal defense_destroyed(defense: DefenseBase)

@export_range(0, 10000, 1) var build_cost: int = 25

@onready var health_component: HealthComponent = $HealthComponent
@onready var team_component: TeamComponent = $TeamComponent


func _ready() -> void:
	# Defenses are ground objects and must share Z=0 with props/actors so the
	# arena Y-sort can place them correctly by their feet position.
	z_index = 0
	add_to_group("defenses")
	health_component.died.connect(_on_health_died)


func get_build_cost() -> int:
	return build_cost


func multiply_damage(multiplier: float) -> void:
	var weapon := get_node_or_null("WeaponComponent") as WeaponComponent
	if weapon != null:
		weapon.set_damage_multiplier(weapon.damage_multiplier * maxf(multiplier, 0.0))


func multiply_fire_rate(multiplier: float) -> void:
	var weapon := get_node_or_null("WeaponComponent") as WeaponComponent
	if weapon != null:
		weapon.set_fire_rate_multiplier(weapon.fire_rate_multiplier * maxf(multiplier, 0.01))


func multiply_max_health(multiplier: float) -> void:
	if multiplier <= 0.0:
		return
	var old_max := health_component.max_health
	health_component.max_health = maxf(old_max * multiplier, 1.0)
	var added := health_component.max_health - old_max
	health_component.current_health = clampf(
		health_component.current_health + maxf(added, 0.0),
		0.0,
		health_component.max_health
	)
	health_component.health_changed.emit(
		health_component.current_health,
		health_component.max_health
	)


func _on_health_died() -> void:
	defense_destroyed.emit(self)
	queue_free()
