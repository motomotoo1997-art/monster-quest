extends Resource
class_name UpgradeDefinition

enum Operation {
	ADD,
	MULTIPLY,
}

@export var id: StringName
@export var display_name: String = "Upgrade"
@export_multiline var description: String = ""
@export var stat_key: StringName
@export var operation: Operation = Operation.ADD
@export var amount: float = 0.0
@export_file("*.png", "*.svg", "*.webp") var icon_path: String = ""
