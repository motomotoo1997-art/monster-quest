extends Node
class_name UpgradeController

signal upgrade_selected(id: StringName)

const DEFAULT_UPGRADES: Array[UpgradeDefinition] = [
	preload("res://data/upgrades/weapon_damage.tres"),
	preload("res://data/upgrades/fire_rate.tres"),
	preload("res://data/upgrades/projectile_speed.tres"),
	preload("res://data/upgrades/max_hp.tres"),
	preload("res://data/upgrades/dash_recovery.tres"),
	preload("res://data/upgrades/turret_damage.tres"),
	preload("res://data/upgrades/turret_fire_rate.tres"),
	preload("res://data/upgrades/defense_max_hp.tres"),
	preload("res://data/upgrades/gold_pickup_value.tres"),
	preload("res://data/upgrades/crit_chance.tres"),
	preload("res://data/upgrades/trailblazer.tres"),
	preload("res://data/upgrades/piercing_rounds.tres"),
]

@export var player_path: NodePath
@export var economy_path: NodePath
@export var build_controller_path: NodePath

var upgrade_definitions: Array[UpgradeDefinition] = DEFAULT_UPGRADES.duplicate()
var rng := RandomNumberGenerator.new()
var turret_damage_multiplier := 1.0
var turret_fire_rate_multiplier := 1.0
var defense_health_multiplier := 1.0

var player: Prospector
var economy: EconomyController
var build_controller: BuildController


func _ready() -> void:
	player = get_node_or_null(player_path) as Prospector
	economy = get_node_or_null(economy_path) as EconomyController
	build_controller = get_node_or_null(build_controller_path) as BuildController
	if build_controller != null:
		build_controller.defense_built.connect(_on_defense_built)


func set_rng_seed(value: int) -> void:
	rng.seed = value


func roll_choices(count: int = 3) -> Array[UpgradeDefinition]:
	var result: Array[UpgradeDefinition] = []
	if count <= 0 or upgrade_definitions.is_empty():
		return result
	var pool: Array[UpgradeDefinition] = upgrade_definitions.duplicate()
	var chosen_ids: Dictionary = {}
	while result.size() < count and not pool.is_empty():
		var index: int = rng.randi_range(0, pool.size() - 1)
		var definition: UpgradeDefinition = pool.pop_at(index) as UpgradeDefinition
		if definition == null or definition.id == StringName() or chosen_ids.has(definition.id):
			continue
		chosen_ids[definition.id] = true
		result.append(definition)
	return result


func apply_upgrade(id: StringName) -> void:
	var definition := _find_definition(id)
	if definition == null:
		return
	match definition.stat_key:
		&"weapon_damage":
			if player != null:
				player.multiply_weapon_damage(definition.amount)
		&"fire_rate":
			if player != null:
				player.multiply_fire_rate(definition.amount)
		&"projectile_speed":
			if player != null:
				player.multiply_projectile_speed(definition.amount)
		&"max_hp":
			if player != null:
				player.add_max_health(definition.amount)
		&"dash_recovery":
			if player != null:
				player.multiply_dash_recovery(definition.amount)
		&"turret_damage":
			turret_damage_multiplier *= definition.amount
			_apply_damage_to_existing_defenses(definition.amount)
		&"turret_fire_rate":
			turret_fire_rate_multiplier *= definition.amount
			_apply_fire_rate_to_existing_defenses(definition.amount)
		&"defense_max_hp":
			defense_health_multiplier *= definition.amount
			_apply_health_to_existing_defenses(definition.amount)
		&"gold_pickup_value":
			if economy != null:
				economy.multiply_pickup_value(definition.amount)
		&"crit_chance":
			if player != null:
				player.add_crit_chance(definition.amount)
		&"move_speed":
			if player != null:
				player.multiply_move_speed(definition.amount)
		&"projectile_pierce":
			if player != null:
				player.add_projectile_pierce(int(round(definition.amount)))
		_:
			return
	upgrade_selected.emit(definition.id)


func _find_definition(id: StringName) -> UpgradeDefinition:
	for definition in upgrade_definitions:
		if definition != null and definition.id == id:
			return definition
	return null


func _apply_damage_to_existing_defenses(multiplier: float) -> void:
	for node in get_tree().get_nodes_in_group("defenses"):
		if node is DefenseBase:
			(node as DefenseBase).multiply_damage(multiplier)


func _apply_fire_rate_to_existing_defenses(multiplier: float) -> void:
	for node in get_tree().get_nodes_in_group("defenses"):
		if node is DefenseBase:
			(node as DefenseBase).multiply_fire_rate(multiplier)


func _apply_health_to_existing_defenses(multiplier: float) -> void:
	for node in get_tree().get_nodes_in_group("defenses"):
		if node is DefenseBase:
			(node as DefenseBase).multiply_max_health(multiplier)


func _on_defense_built(defense: DefenseBase) -> void:
	if defense == null:
		return
	if not is_equal_approx(turret_damage_multiplier, 1.0):
		defense.multiply_damage(turret_damage_multiplier)
	if not is_equal_approx(turret_fire_rate_multiplier, 1.0):
		defense.multiply_fire_rate(turret_fire_rate_multiplier)
	if not is_equal_approx(defense_health_multiplier, 1.0):
		defense.multiply_max_health(defense_health_multiplier)
