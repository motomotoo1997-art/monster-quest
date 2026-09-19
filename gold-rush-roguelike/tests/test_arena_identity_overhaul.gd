extends SceneTree

const CASES := [
	{"scene":"res://scenes/arenas/Arena02.tscn","backdrop":"arena02_mining_yard_v6.svg","landmark":"MiningHoist"},
	{"scene":"res://scenes/arenas/Arena03.tscn","backdrop":"arena03_rail_explosives_v6.svg","landmark":"TNTDepot"},
	{"scene":"res://scenes/arenas/Arena04.tscn","backdrop":"arena04_elite_canyon_v6.svg","landmark":"ExtractionRig"},
]

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	for entry in CASES:
		var packed := load(entry.scene) as PackedScene
		if packed == null:
			_fail("Arena must load: %s" % entry.scene)
			return
		var arena := packed.instantiate()
		root.add_child(arena)
		await process_frame
		var backdrop := arena.get_node_or_null("IllustratedBackdrop") as Sprite2D
		if backdrop == null or backdrop.texture == null or not backdrop.texture.resource_path.ends_with(entry.backdrop):
			_fail("Arena needs its unique frontier v6 backdrop: %s" % entry.scene)
			return
		var landmark := arena.get_node_or_null(entry.landmark) as Sprite2D
		if landmark == null or landmark.texture == null or not landmark.visible:
			_fail("Arena unique landmark missing: %s/%s" % [entry.scene, entry.landmark])
			return
		for group_name in [&"player_spawn",&"core_spawn",&"enemy_spawn",&"build_zone"]:
			var count := 0
			for node in arena.find_children("*","Node",true,false):
				if node.is_in_group(group_name):
					count += 1
			if count == 0:
				_fail("Arena marker group missing after art replacement: %s/%s" % [entry.scene, group_name])
				return
		arena.queue_free()
		await process_frame
	print("PASS: Arena02-04 have distinct frontier identities and preserve gameplay markers")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
