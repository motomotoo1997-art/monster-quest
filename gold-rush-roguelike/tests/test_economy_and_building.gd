extends SceneTree


func _init() -> void:
	var economy := EconomyController.new()
	root.add_child(economy)
	economy.add_gold(100)
	assert(economy.can_afford(60))
	assert(economy.spend_gold(60))
	assert(economy.gold == 40)
	assert(not economy.spend_gold(50))
	assert(economy.gold == 40)
	assert(not economy.spend_gold(-1), "Negative costs must be rejected")
	assert(economy.gold == 40)
	economy.queue_free()
	quit(0)
