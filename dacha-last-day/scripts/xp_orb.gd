extends Area2D

@export var value: int = 7
var player: Node2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	player = get_tree().get_first_node_in_group("player") as Node2D

func _physics_process(delta: float) -> void:
	if is_instance_valid(player) and global_position.distance_to(player.global_position) < 150.0:
		global_position = global_position.move_toward(player.global_position, 240.0 * delta)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.gain_xp(value)
		queue_free()
