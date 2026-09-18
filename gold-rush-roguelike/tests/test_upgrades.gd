extends SceneTree


func _init() -> void:
	var controller := UpgradeController.new()
	controller.upgrade_definitions = []
	for index in range(6):
		var definition := UpgradeDefinition.new()
		definition.id = StringName("upgrade_%d" % index)
		definition.display_name = "Upgrade %d" % index
		definition.stat_key = &"test"
		controller.upgrade_definitions.append(definition)
	controller.set_rng_seed(1337)
	var choices := controller.roll_choices(3)
	assert(choices.size() == 3)
	var ids: Dictionary = {}
	for choice in choices:
		ids[choice.id] = true
	assert(ids.size() == 3, "Upgrade roll must contain unique IDs")
	controller.free()
	quit(0)
