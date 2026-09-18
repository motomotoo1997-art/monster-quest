extends Area2D
class_name GoldPickup

signal collected(amount: int)

@export_range(1, 10000, 1) var amount: int = 1
@export_range(0.0, 1000.0, 1.0) var bob_height: float = 4.0
@export_range(0.1, 10.0, 0.1) var bob_speed: float = 3.0

var _time := 0.0
var _visual_start_y := 0.0

@onready var visual: Node2D = $Visual


func _ready() -> void:
	_visual_start_y = visual.position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	visual.position.y = _visual_start_y + sin(_time * bob_speed) * bob_height


func configure(gold_amount: int) -> void:
	amount = maxi(gold_amount, 1)


func _on_body_entered(body: Node2D) -> void:
	var team := body.get_node_or_null("TeamComponent") as TeamComponent
	if team == null or team.team != TeamComponent.Team.PLAYER:
		return
	var economy := get_tree().get_first_node_in_group("economy_controller") as EconomyController
	if economy == null:
		return
	economy.add_gold(amount)
	collected.emit(amount)
	queue_free()
