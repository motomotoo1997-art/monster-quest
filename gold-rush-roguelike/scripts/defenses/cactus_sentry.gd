extends DefenseBase
class_name CactusSentry

var _recoil := 0.0
var _fire_visual_remaining := 0.0
var _visual_base_position := Vector2.ZERO
var _visual_base_scale := Vector2.ONE

@onready var targeting_component: TargetingComponent = $TargetingComponent
@onready var weapon_component: WeaponComponent = $WeaponComponent
@onready var aim_pivot: Node2D = $AimPivot
@onready var muzzle: Marker2D = $AimPivot/Muzzle
@onready var visual: AnimatedSprite2D = $Visual


func _ready() -> void:
	super()
	_visual_base_position = visual.position
	_visual_base_scale = visual.scale
	visual.play(&"idle")
	weapon_component.fired.connect(_on_weapon_fired)


func _physics_process(delta: float) -> void:
	_recoil = move_toward(_recoil, 0.0, delta * 8.0)
	_fire_visual_remaining = maxf(_fire_visual_remaining - delta, 0.0)
	var next_animation: StringName = &"fire" if _fire_visual_remaining > 0.0 else &"idle"
	if visual.animation != next_animation:
		visual.play(next_animation)
	visual.position = _visual_base_position + Vector2(0.0, _recoil * 2.5)
	visual.scale = Vector2(
		_visual_base_scale.x * (1.0 + _recoil * 0.035),
		_visual_base_scale.y * (1.0 - _recoil * 0.045)
	)
	var target := targeting_component.get_nearest_hostile(global_position)
	if target == null:
		return
	var direction := muzzle.global_position.direction_to(target.global_position)
	aim_pivot.rotation = direction.angle()
	weapon_component.try_fire(muzzle.global_position, direction, team_component.team)


func _on_weapon_fired(_projectile: Node2D) -> void:
	_recoil = 1.0
	_fire_visual_remaining = 0.18
	visual.play(&"fire")
