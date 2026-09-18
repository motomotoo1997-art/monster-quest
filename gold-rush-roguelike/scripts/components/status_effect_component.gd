extends Node
class_name StatusEffectComponent

signal effect_started(effect_id: StringName, duration: float)
signal effect_ended(effect_id: StringName)

var _remaining: Dictionary = {}


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	var expired: Array[StringName] = []
	for effect_id: StringName in _remaining.keys():
		var next_time := maxf(float(_remaining[effect_id]) - delta, 0.0)
		_remaining[effect_id] = next_time
		if next_time <= 0.0:
			expired.append(effect_id)
	for effect_id in expired:
		_remaining.erase(effect_id)
		effect_ended.emit(effect_id)
	if _remaining.is_empty():
		set_process(false)


func apply_effect(effect_id: StringName, duration: float) -> void:
	if effect_id == StringName() or duration <= 0.0:
		return
	_remaining[effect_id] = duration
	effect_started.emit(effect_id, duration)
	set_process(true)


func clear_effect(effect_id: StringName) -> void:
	if not _remaining.has(effect_id):
		return
	_remaining.erase(effect_id)
	effect_ended.emit(effect_id)
	if _remaining.is_empty():
		set_process(false)


func clear_all() -> void:
	var active_ids := _remaining.keys()
	_remaining.clear()
	for effect_id in active_ids:
		effect_ended.emit(effect_id)
	set_process(false)


func has_effect(effect_id: StringName) -> bool:
	return _remaining.has(effect_id)


func get_remaining(effect_id: StringName) -> float:
	return float(_remaining.get(effect_id, 0.0))
