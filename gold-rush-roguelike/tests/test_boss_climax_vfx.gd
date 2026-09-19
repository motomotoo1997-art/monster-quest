extends SceneTree

const BOSS_SCENE := "res://scenes/enemies/GoldBarTank.tscn"
const MAIN_SCENE := "res://scenes/main/Main.tscn"

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var boss_packed := load(BOSS_SCENE) as PackedScene
	if boss_packed == null:
		_fail("GoldBarTank scene must load for climax VFX regression")
		return
	var boss := boss_packed.instantiate() as GoldBarTank
	if boss == null:
		_fail("GoldBarTank scene must instantiate for climax VFX regression")
		return
	root.add_child(boss)
	await process_frame

	var phase_aura := boss.get_node_or_null("PhaseAura") as Node2D
	var phase_light := boss.get_node_or_null("PhaseAura/PhaseLight") as PointLight2D
	var phase_ring := boss.get_node_or_null("PhaseAura/PhaseRing") as Line2D
	if phase_aura == null or phase_light == null or phase_ring == null:
		_fail("Boss needs a PhaseAura with local light and readable ring")
		return
	if phase_ring.width < 4.0:
		_fail("Boss phase ring must be thick enough to read behind the tank")
		return

	boss.phase = 1
	boss.state = GoldBarTank.State.CHASE
	boss._update_visual(0.0)
	if phase_aura.visible:
		_fail("Phase one should keep the boss aura dormant")
		return

	boss.phase = 2
	boss._update_visual(0.1)
	if not phase_aura.visible or phase_light.energy < 0.75:
		_fail("Phase two must visibly power up the boss aura")
		return
	var phase_two_energy := phase_light.energy

	boss.phase = 3
	boss._update_visual(0.1)
	if not phase_aura.visible or phase_light.energy <= phase_two_energy:
		_fail("Phase three must intensify the boss aura beyond phase two")
		return

	boss.queue_free()
	await process_frame

	var main_packed := load(MAIN_SCENE) as PackedScene
	if main_packed == null:
		_fail("Main scene must load for boss climax VFX regression")
		return
	var main := main_packed.instantiate() as GoldRushMain
	if main == null:
		_fail("Main scene must instantiate for boss climax VFX regression")
		return
	root.add_child(main)
	await process_frame
	if main.boss_death_vfx_scene == null:
		_fail("Main must expose a dedicated boss death VFX scene")
		return
	var death_vfx := main.boss_death_vfx_scene.instantiate() as Node2D
	if death_vfx == null:
		_fail("Boss death VFX scene must instantiate")
		return
	root.add_child(death_vfx)
	await process_frame
	if not death_vfx.is_in_group("boss_climax_vfx"):
		_fail("Boss death VFX must be discoverable as boss_climax_vfx")
		return
	var core_flash := death_vfx.get_node_or_null("CoreFlash") as PointLight2D
	var shock_ring := death_vfx.get_node_or_null("ShockRing") as Line2D
	var shards := death_vfx.get_node_or_null("GoldShards") as Node2D
	var dust := death_vfx.get_node_or_null("Dust") as CPUParticles2D
	if core_flash == null or core_flash.energy < 2.0:
		_fail("Boss death needs a strong local energy flash")
		return
	if shock_ring == null or shock_ring.width < 4.0:
		_fail("Boss death needs a thick shock ring")
		return
	if shards == null or shards.get_child_count() < 10:
		_fail("Boss death needs at least ten authored gold debris shards")
		return
	if dust == null or dust.amount < 18 or not dust.one_shot:
		_fail("Boss death needs a dense one-shot dust burst")
		return

	death_vfx.queue_free()
	main.queue_free()
	print("PASS: Gold Bar Tank phases and death use dedicated climax VFX")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
