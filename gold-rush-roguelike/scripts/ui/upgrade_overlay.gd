extends CanvasLayer
class_name UpgradeOverlay

signal choice_made(id: StringName)

@export var upgrade_controller_path: NodePath

var choices: Array[UpgradeDefinition] = []
var upgrade_controller: UpgradeController

@onready var panel: Control = $Root
@onready var title_label: Label = $Root/Panel/Margin/VBox/Title
@onready var buttons: Array[Button] = [
	$Root/Panel/Margin/VBox/Cards/Card1,
	$Root/Panel/Margin/VBox/Cards/Card2,
	$Root/Panel/Margin/VBox/Cards/Card3,
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	upgrade_controller = get_node_or_null(upgrade_controller_path) as UpgradeController
	panel.visible = false
	for index in range(buttons.size()):
		buttons[index].pressed.connect(_select_choice.bind(index))


func present(new_choices: Array[UpgradeDefinition]) -> void:
	choices = new_choices.duplicate()
	if choices.is_empty():
		choice_made.emit(StringName())
		return
	title_label.text = "CHOOSE YOUR EDGE"
	for index in range(buttons.size()):
		var button := buttons[index]
		if index >= choices.size():
			button.visible = false
			continue
		var choice := choices[index]
		button.visible = true
		button.disabled = false
		button.text = "%d  %s\n%s" % [index + 1, choice.display_name, choice.description]
	panel.visible = true
	get_tree().paused = true
	buttons[0].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible or not event.is_pressed():
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		match key_event.keycode:
			KEY_1:
				_select_choice(0)
			KEY_2:
				_select_choice(1)
			KEY_3:
				_select_choice(2)


func _select_choice(index: int) -> void:
	if index < 0 or index >= choices.size():
		return
	var choice := choices[index]
	for button in buttons:
		button.disabled = true
	if upgrade_controller != null:
		upgrade_controller.apply_upgrade(choice.id)
	panel.visible = false
	get_tree().paused = false
	choice_made.emit(choice.id)
