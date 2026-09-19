extends DefenseBase
class_name MagneticTurret

signal target_changed(target: Node2D)

var _current_target: Node2D
var _recoil := 0.0
var _visual_time := 0.0
var _visual_base_position := Vector2.ZERO
var _visual_base_scale := Vector2.ONE

@onready var targeting_component: TargetingComponent = $TargetingComponent
@onready var weapon_component: WeaponComponent = $WeaponComponent
@onready var aim_pivot: Node2D = $AimPivot
@onready var muzzle: Marker2D = $AimPivot/Muzzle
@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	super()
	_visual_base_position = visual.position
	_visual_base_scale = visual.scale
	weapon_component.fired.connect(_on_weapon_fired)


func _physics_process(delta: float) -> void:
	_visual_time += delta
	_recoil = move_toward(_recoil, 0.0, delta * 6.5)
	var hum := sin(_visual_time * 6.0) * 0.8
	visual.position = _visual_base_position + Vector2(0.0, hum + _recoil * 3.0)
	visual.scale = Vector2(
		_visual_base_scale.x * (1.0 + _recoil * 0.04),
		_visual_base_scale.y * (1.0 - _recoil * 0.05)
	)
	var target := targeting_component.get_nearest_hostile(global_position)
	if target != _current_target:
		_current_target = target
		target_changed.emit(target)
	if target == null:
		return
	var direction := muzzle.global_position.direction_to(target.global_position)
	aim_pivot.rotation = direction.angle()
	weapon_component.try_fire(muzzle.global_position, direction, team_component.team)


func _on_weapon_fired(_projectile: Node2D) -> void:
	_recoil = 1.0
