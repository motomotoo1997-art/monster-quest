extends SceneTree

const GROUND_SORT_Z := 5
const GROUND_SORT_SCENES := [
	"res://scenes/enemies/GoldHopper.tscn",
	"res://scenes/enemies/GoldCoinSentinel.tscn",
	"res://scenes/enemies/MoltenGoldSlime.tscn",
	"res://scenes/enemies/GoldBarTank.tscn",
	"res://scenes/defenses/MagneticTurret.tscn",
	"res://scenes/defenses/CactusSentry.tscn",
	"res://scenes/defenses/TNTBarrel.tscn",
	"res://scenes/environment/CactusProp.tscn",
	"res://scenes/environment/RockClusterProp.tscn",
	"res://scenes/environment/MineCartProp.tscn",
	"res://scenes/environment/GoldVeinProp.tscn",
	"res://scenes/environment/RailSegmentProp.tscn",
	"res://scenes/environment/CrateStackProp.tscn",
]

func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene must load")
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame

	var arena_controller := main.get_node_or_null("ArenaController") as ArenaController
	var player := main.get_node_or_null("Actors/Prospector") as Prospector
	var core := main.get_node_or_null("Actors/GoldCore") as GoldCore
	var build_controller := main.get_node_or_null("BuildController") as BuildController
	if arena_controller == null or player == null or core == null or build_controller == null:
		_fail("Main depth-sort dependencies must exist")
		return
	if player.z_index != GROUND_SORT_Z or core.z_index != GROUND_SORT_Z:
		_fail("Persistent ground actors must share the common ground z-index")
		return

	for scene_path in GROUND_SORT_SCENES:
		var ground_packed := load(scene_path) as PackedScene
		if ground_packed == null:
			_fail("Ground-sort scene must load: %s" % scene_path)
			return
		var ground_item := ground_packed.instantiate() as Node2D
		if ground_item == null:
			_fail("Ground-sort scene root must be Node2D: %s" % scene_path)
			return
		if ground_item.z_index != GROUND_SORT_Z:
			_fail("Ground-sort z-index mismatch (%d): %s" % [ground_item.z_index, scene_path])
			return
		ground_item.free()

	if not arena_controller.load_arena(1):
		_fail("Arena01 must load")
		return
	await process_frame
	var arena_one := arena_controller.current_arena
	if arena_one == null or not arena_one.y_sort_enabled:
		_fail("Active arena must be the shared Y-sort canvas")
		return
	if player.get_parent() != arena_one or core.get_parent() != arena_one:
		_fail("Prospector and Gold Core must join the active arena Y-sort hierarchy")
		return
	if not build_controller.has_method("get_build_parent"):
		_fail("BuildController must expose the active arena build parent")
		return
	if build_controller.get_build_parent() != arena_one:
		_fail("Defenses must be placed inside the active arena Y-sort hierarchy")
		return

	if not arena_controller.load_arena(2):
		_fail("Arena02 must load")
		return
	await process_frame
	var arena_two := arena_controller.current_arena
	if arena_two == null or arena_two == arena_one:
		_fail("Arena transition must replace the arena")
		return
	if not is_instance_valid(player) or not is_instance_valid(core):
		_fail("Persistent actors must survive arena replacement")
		return
	if player.get_parent() != arena_two or core.get_parent() != arena_two:
		_fail("Persistent actors must rejoin the new arena Y-sort hierarchy")
		return
	if build_controller.get_build_parent() != arena_two:
		_fail("Build parent must follow the active arena after transition")
		return

	print("PASS: grounded world items share z-index and one Y-sort hierarchy across arena transitions")
	quit(0)


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
