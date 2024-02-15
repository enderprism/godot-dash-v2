@tool
class_name tMove extends "res://src/components/triggers/tEasableTrigger.gd"

# @@buttons("Start Preview", _run(_target_group), "Stop Preview", _cancel())

@export var _use_target: bool:
	set(value):
		_use_target = value
		notify_property_list_changed()

@export var _move_target: Node2D
@export var _move_coordinates: Vector2

func _validate_property(property: Dictionary) -> void:
	if property.name in ["_move_coordinates"] and _use_target:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_move_target"] and not _use_target:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func _init():
	_texture = preload("res://assets/textures/triggers/Move.svg")

func _run(_body: Node2D) -> void:
	if Engine.is_editor_hint():
		if self in EditorInterface.get_selection().get_selected_nodes():
			if not _initial_value_set:
				_initial_value = _target_group.global_position
				_initial_value_set = true
			else:
				_target_group.global_position = _initial_value
	else:
		_initial_value = _target_group.global_position
		_initial_value_set = true
	_start_lerp_tween()

func _process(delta: float) -> void:
	super(delta)
	if _target_group != null:
		if Engine.is_editor_hint():
			var _final_value: Vector2
			if not _relative:
				if _use_target and _move_target != null:
					_final_value = _move_target.global_position
				else:
					_final_value = _move_coordinates
			elif _initial_value_set:
				_final_value = _initial_value + _move_coordinates
			if self in EditorInterface.get_selection().get_selected_nodes():
				_set_value()
			else:
				_initial_value_set = false
			if _target_group.global_position == _final_value and not _lerp_tween.is_running():
				_cancel()
		else:
			_set_value()

func _set_value() -> void:
	if _initial_value_set:
		if not _relative:
			if _use_target:
				_target_group.global_position = lerp(_initial_value, _move_target.global_position, _get_lerp_weight())
			else:
				_target_group.global_position = lerp(_initial_value, _move_coordinates, _get_lerp_weight())
		else:
			_target_group.global_position = lerp(_initial_value, _initial_value + _move_coordinates, _get_lerp_weight())

func _cancel() -> void:
	super()
	_target_group.global_position = _initial_value
