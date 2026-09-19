extends SceneTree

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

	print("PASS: arena props, persistent actors and defenses share one Y-sort hierarchy across transitions")
	quit(0)


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
