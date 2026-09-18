extends StaticBody2D
class_name GoldCore

signal core_destroyed

@onready var health_component: HealthComponent = $HealthComponent
@onready var team_component: TeamComponent = $TeamComponent


func _ready() -> void:
	health_component.died.connect(_on_health_died)


func is_alive() -> bool:
	return not health_component.is_dead()


func _on_health_died() -> void:
	core_destroyed.emit()
