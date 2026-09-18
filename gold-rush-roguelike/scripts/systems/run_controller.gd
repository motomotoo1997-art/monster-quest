extends Node
class_name RunController

signal run_started
signal run_failed(reason: String)
signal run_won

var is_run_active := false
var is_run_complete := false


func start_new_run() -> void:
	is_run_active = true
	is_run_complete = false
	run_started.emit()


func fail_run(reason: String) -> void:
	if not is_run_active or is_run_complete:
		return
	is_run_active = false
	is_run_complete = true
	run_failed.emit(reason)


func win_run() -> void:
	if not is_run_active or is_run_complete:
		return
	is_run_active = false
	is_run_complete = true
	run_won.emit()
