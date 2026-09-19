extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene must load")
		return
	var main := packed.instantiate() as GoldRushMain
	root.add_child(main)
	await process_frame

	var events := main.get_node_or_null("ArenaEventController")
	if events == null:
		_fail("Main must own ArenaEventController")
		return
	if not events.has_method("start_wave_event") or not events.has_method("stop_event"):
		_fail("ArenaEventController needs explicit wave-event lifecycle")
		return
	if not events.has_method("get_event_config"):
		_fail("ArenaEventController needs authored event lookup")
		return

	var early: Dictionary = events.call("get_event_config",1,1)
	if not early.is_empty():
		_fail("Arena01 must stay clean while the player learns core combat")
		return
	var dynamite: Dictionary = events.call("get_event_config",3,2)
	if StringName(dynamite.get("id",&"")) != &"dynamite_rain":
		_fail("Arena03 wave 2 must introduce dynamite rain")
		return
	if float(dynamite.get("telegraph",0.0)) < 0.55:
		_fail("Dynamite rain must give a fair readable telegraph")
		return
	var molten: Dictionary = events.call("get_event_config",4,3)
	if StringName(molten.get("id",&"")) != &"molten_burst":
		_fail("Arena04 wave 3 must escalate to molten bursts")
		return
	if int(molten.get("strikes",0)) < 2:
		_fail("Late molten event must create a multi-strike pattern")
		return

	main.arena_controller.load_arena(3)
	await process_frame
	events.call("start_wave_event",3,2)
	if StringName(events.get("active_event_id")) != &"dynamite_rain":
		_fail("Starting Arena03 wave 2 must activate dynamite rain")
		return
	if not events.has_method("get_active_telegraph_count") or int(events.call("get_active_telegraph_count")) < 1:
		_fail("Arena event must immediately expose a readable hazard telegraph")
		return
	var telegraph := main.arena_controller.current_arena.find_child("ArenaHazardTelegraph",true,false) as Node2D
	if telegraph == null or telegraph.get_node_or_null("DangerRing") == null:
		_fail("Arena hazard telegraph needs an authored warning ring in the active arena")
		return
	events.call("stop_event")
	if StringName(events.get("active_event_id")) != &"":
		_fail("Stopping a wave event must clear active event state")
		return

	main.queue_free()
	print("PASS: authored arena events escalate late-run combat with fair telegraphs")
	quit(0)

func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
