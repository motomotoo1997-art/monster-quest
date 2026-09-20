extends Area2D
class_name ProjectileComponent

@export_range(1.0, 5000.0, 1.0) var speed: float = 900.0
@export_range(0.0, 100000.0, 0.5) var damage: float = 10.0
@export_range(0.05, 30.0, 0.05) var lifetime: float = 2.0
@export var impact_scene: PackedScene

var direction: Vector2 = Vector2.RIGHT
var owner_team: TeamComponent.Team = TeamComponent.Team.NEUTRAL
var _remaining_lifetime: float = 2.0
var _configured := false
var pierce_remaining: int = 0
var _hit_hurtboxes: Dictionary = {}
var is_critical := false
var _piercing_shot := false
var _visual_time := 0.0

@onready var pierce_halo: CanvasItem = get_node_or_null("PierceHalo") as CanvasItem
@onready var crit_core: CanvasItem = get_node_or_null("CritCore") as CanvasItem


func _ready() -> void:
	_remaining_lifetime = lifetime
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not _configured:
		return
	global_position += direction * speed * delta
	_visual_time += delta
	_update_trait_visuals()
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


func set_shot_traits(critical: bool, pierce_count: int) -> void:
	is_critical = critical
	pierce_remaining = maxi(pierce_count,0)
	_piercing_shot = pierce_remaining > 0
	if pierce_halo != null:
		pierce_halo.visible = _piercing_shot
	if crit_core != null:
		crit_core.visible = is_critical
	_update_trait_visuals()


func _update_trait_visuals() -> void:
	if pierce_halo != null and pierce_halo.visible:
		var pierce_pulse := 1.0 + sin(_visual_time * 15.0) * 0.08
		pierce_halo.scale = Vector2.ONE * pierce_pulse
		pierce_halo.modulate.a = 0.78 + sin(_visual_time * 12.0) * 0.18
	if crit_core != null and crit_core.visible:
		var crit_pulse := 1.0 + sin(_visual_time * 19.0) * 0.12
		crit_core.scale = Vector2.ONE * crit_pulse


func _spawn_impact_feedback() -> void:
	if impact_scene == null or not is_inside_tree():
		return
	var impact := impact_scene.instantiate() as Node2D
	if impact == null:
		return
	if is_critical:
		impact.scale = Vector2.ONE * 1.22
		impact.modulate = Color(1.0,0.78,0.32,1.0)
	elif _piercing_shot:
		impact.scale = Vector2.ONE * 1.08
		impact.modulate = Color(0.62,0.96,1.0,1.0)
	var target_parent := get_tree().current_scene
	if target_parent == null:
		target_parent = get_parent()
	if target_parent != null:
		target_parent.add_child(impact)
		impact.global_position = global_position


func _on_area_entered(area: Area2D) -> void:
	if not area is HurtboxComponent:
		return
	var hurtbox := area as HurtboxComponent
	var hurtbox_id := hurtbox.get_instance_id()
	if _hit_hurtboxes.has(hurtbox_id):
		return
	var knockback := direction * minf(speed * 0.08,160.0)
	if not hurtbox.receive_hit(damage,owner_team,knockback):
		return
	_hit_hurtboxes[hurtbox_id] = true
	_spawn_impact_feedback()
	if pierce_remaining > 0:
		pierce_remaining -= 1
		return
	queue_free()


func _on_body_entered(_body: Node2D) -> void:
	queue_free()
