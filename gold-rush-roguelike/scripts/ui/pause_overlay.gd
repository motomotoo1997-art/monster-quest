extends CanvasLayer
class_name PauseOverlay

@onready var root_panel: Control = $Root
@onready var resume_button: Button = $Root/Panel/Margin/VBox/Resume
@onready var restart_button: Button = $Root/Panel/Margin/VBox/Restart

var pause_enabled := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	root_panel.visible = false
	resume_button.pressed.connect(resume_game)
	restart_button.pressed.connect(_restart)


func _unhandled_input(event: InputEvent) -> void:
	if not pause_enabled or not event.is_action_pressed("pause"):
		return
	if root_panel.visible:
		resume_game()
	elif not get_tree().paused:
		pause_game()
	get_viewport().set_input_as_handled()


func set_pause_enabled(enabled: bool) -> void:
	pause_enabled = enabled
	if not enabled and root_panel.visible:
		resume_game()


func pause_game() -> void:
	if not pause_enabled or get_tree().paused:
		return
	root_panel.visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func resume_game() -> void:
	if not root_panel.visible:
		return
	root_panel.visible = false
	get_tree().paused = false


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
