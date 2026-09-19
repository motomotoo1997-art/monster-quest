extends StaticBody2D
class_name GoldCore

signal core_destroyed

@onready var health_component: HealthComponent = $HealthComponent
@onready var team_component: TeamComponent = $TeamComponent
@onready var energy_rings: Node2D = $EnergyRings
@onready var aura: Polygon2D = $Aura

var _visual_pulse_phase := 0.0


func _ready() -> void:
	health_component.died.connect(_on_health_died)


func _process(delta: float) -> void:
	_visual_pulse_phase = fmod(_visual_pulse_phase + delta * 2.6, TAU)
	var pulse := (sin(_visual_pulse_phase) + 1.0) * 0.5
	var pulse_scale := lerpf(0.96, 1.055, pulse)
	energy_rings.scale = Vector2.ONE * pulse_scale
	energy_rings.rotation = sin(_visual_pulse_phase * 0.5) * 0.035
	energy_rings.modulate.a = lerpf(0.68, 1.0, pulse)
	aura.modulate.a = lerpf(0.62, 1.0, pulse)


func get_visual_pulse_phase() -> float:
	return _visual_pulse_phase


func is_alive() -> bool:
	return not health_component.is_dead()


func _on_health_died() -> void:
	core_destroyed.emit()
