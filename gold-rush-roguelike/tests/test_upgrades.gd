extends SceneTree


func _init() -> void:
	var controller := UpgradeController.new()
	controller.upgrade_definitions.clear()
	for index in range(6):
		var definition := UpgradeDefinition.new()
		definition.id = StringName("upgrade_%d" % index)
		definition.display_name = "Upgrade %d" % index
		definition.stat_key = &"test"
		controller.upgrade_definitions.append(definition)

	controller.set_rng_seed(1337)
	var choices := controller.roll_choices(3)
	if choices.size() != 3:
		_fail("Expected 3 upgrade choices, got %d" % choices.size())
		return

	var ids: Dictionary = {}
	for choice in choices:
		ids[choice.id] = true
	if ids.size() != 3:
		_fail("Upgrade roll must contain 3 unique IDs, got %d" % ids.size())
		return

	controller.free()
	print("PASS: upgrade choices are deterministic and unique")
	quit(0)


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
