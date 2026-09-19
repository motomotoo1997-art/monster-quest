extends DefenseBase
class_name TNTBarrel

signal exploded(world_position: Vector2)

@export_range(0.0, 5.0, 0.05) var arm_delay: float = 0.45
@export_range(0.0, 10000.0, 1.0) var explosion_damage: float = 72.0
@export_range(0.0, 2000.0, 1.0) var knockback_strength: float = 240.0

var _arm_remaining := 0.0
var _armed := false
var _exploded := false
var _visual_time := 0.0
var _visual_base_scale := Vector2.ONE

@onready var trigger_area: Area2D = $TriggerArea
@onready var blast_area: Area2D = $BlastArea
@onready var visual: AnimatedSprite2D = $Visual


func _ready() -> void:
	super()
	_arm_remaining = arm_delay
	_visual_base_scale = visual.scale
	visual.play(&"prearm")
	trigger_area.area_entered.connect(_on_trigger_area_entered)


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	_visual_time += delta
	if not _armed:
		_arm_remaining = maxf(_arm_remaining - delta, 0.0)
		if _arm_remaining <= 0.0:
			_armed = true
			visual.play(&"armed")
	_update_visual()


func trigger() -> void:
	if _armed and not _exploded:
		_explode()


func _update_visual() -> void:
	if not _armed:
		if visual.animation != &"prearm":
			visual.play(&"prearm")
		var prearm := 1.0 + sin(_visual_time * 5.0) * 0.01
		visual.scale = _visual_base_scale * prearm
		visual.modulate = Color.WHITE
		return
	if visual.animation != &"armed":
		visual.play(&"armed")
	var pulse := 0.5 + 0.5 * sin(_visual_time * 12.0)
	visual.scale = _visual_base_scale * (1.0 + pulse * 0.045)
	visual.modulate = Color(1.0, 0.78 + pulse * 0.22, 0.60 + pulse * 0.30, 1.0)


func _on_trigger_area_entered(area: Area2D) -> void:
	if not _armed or _exploded or not area is HurtboxComponent:
		return
	var hurtbox := area as HurtboxComponent
	if hurtbox.team_component == null or not team_component.is_hostile_to(hurtbox.team_component):
		return
	_explode()


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	for area in blast_area.get_overlapping_areas():
		if not area is HurtboxComponent:
			continue
		var hurtbox := area as HurtboxComponent
		var target_team := hurtbox.team_component
		if target_team == null or not team_component.is_hostile_to(target_team):
			continue
		var direction := global_position.direction_to(hurtbox.global_position)
		hurtbox.receive_hit(
			explosion_damage,
			team_component.team,
			direction * knockback_strength
		)
	exploded.emit(global_position)
	queue_free()
