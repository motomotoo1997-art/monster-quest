extends CanvasLayer
class_name TitleOverlay

signal start_requested

@onready var root_panel: Control = $Root
@onready var start_button: Button = $Root/Panel/Margin/VBox/Start


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	start_button.pressed.connect(_request_start)
	root_panel.visible = true
	get_tree().paused = true
	start_button.grab_focus()


func dismiss() -> void:
	root_panel.visible = false
	get_tree().paused = false


func _request_start() -> void:
	start_requested.emit()
