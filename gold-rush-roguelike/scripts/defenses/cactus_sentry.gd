extends DefenseBase
class_name CactusSentry

@onready var targeting_component: TargetingComponent = $TargetingComponent
@onready var weapon_component: WeaponComponent = $WeaponComponent
@onready var aim_pivot: Node2D = $AimPivot
@onready var muzzle: Marker2D = $AimPivot/Muzzle


func _physics_process(_delta: float) -> void:
	var target := targeting_component.get_nearest_hostile(global_position)
	if target == null:
		return
	var direction := muzzle.global_position.direction_to(target.global_position)
	aim_pivot.rotation = direction.angle()
	weapon_component.try_fire(muzzle.global_position, direction, team_component.team)
