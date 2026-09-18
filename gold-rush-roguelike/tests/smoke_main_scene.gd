extends SceneTree


func _init() -> void:
	var scene := load("res://scenes/main/Main.tscn") as PackedScene
	assert(scene != null, "Main scene must load")
	var root := scene.instantiate()
	assert(root != null, "Main scene must instantiate")
	root.queue_free()
	quit(0)
