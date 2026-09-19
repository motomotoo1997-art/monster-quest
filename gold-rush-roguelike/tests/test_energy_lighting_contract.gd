extends SceneTree

const LIGHT_SCENES := [
	{"scene":"res://scenes/vfx/HitFlash.tscn","light":"BurstLight","min_energy":1.0},
	{"scene":"res://scenes/vfx/Explosion.tscn","light":"ExplosionLight","min_energy":1.5},
	{"scene":"res://scenes/objectives/GoldCore.tscn","light":"CoreLight","min_energy":0.75},
	{"scene":"res://scenes/defenses/MagneticTurret.tscn","light":"EnergyLight","min_energy":0.45},
	{"scene":"res://scenes/defenses/CactusSentry.tscn","light":"EnergyLight","min_energy":0.35},
	{"scene":"res://scenes/combat/GoldPickup.tscn","light":"LootLight","min_energy":0.35},
]

func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	for entry in LIGHT_SCENES:
		var packed := load(entry.scene) as PackedScene
		if packed == null:
			_fail("Energy-lit scene must load: %s" % entry.scene)
			return
		var instance := packed.instantiate()
		root.add_child(instance)
		await process_frame
		var light := instance.get_node_or_null(entry.light) as PointLight2D
		if light == null:
			_fail("Energy-lit scene is missing PointLight2D %s: %s" % [entry.light, entry.scene])
			return
		if light.texture == null:
			_fail("Energy light must use a radial falloff texture: %s" % entry.scene)
			return
		if light.energy < float(entry.min_energy):
			_fail("Energy light is too weak for gameplay readability: %s" % entry.scene)
			return
		if light.texture_scale < 0.5:
			_fail("Energy light radius is too small: %s" % entry.scene)
			return
		instance.queue_free()
		await process_frame

	print("PASS: cyan/gold combat energy and loot have local dynamic lighting")
	quit(0)


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
