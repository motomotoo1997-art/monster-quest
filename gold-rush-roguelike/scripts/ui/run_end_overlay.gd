extends CanvasLayer
class_name RunEndOverlay

@onready var root_panel: Control = $Root
@onready var title_label: Label = $Root/Panel/Margin/VBox/Title
@onready var detail_label: Label = $Root/Panel/Margin/VBox/Detail
@onready var restart_button: Button = $Root/Panel/Margin/VBox/Restart


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	root_panel.visible = false
	restart_button.pressed.connect(_restart)


func show_failure(reason: String) -> void:
	title_label.text = "RUN LOST"
	detail_label.text = reason
	_show()


func show_victory() -> void:
	title_label.text = "GOLD RUSH CLEARED"
	detail_label.text = "The Gold Bar Tank is down. The core survived."
	_show()


func _show() -> void:
	root_panel.visible = true
	get_tree().paused = true
	restart_button.grab_focus()


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
