@tool
extends Node2D
class_name tMove

enum Mode {
	SET,
	ADD,
	COPY,
}

@export var _mode: Mode = Mode.ADD:
	set(value):
		_mode = value
		notify_property_list_changed()
@export var _set_position: Vector2
@export var _add_position: Vector2
@export var _copy_target: Node2D
@export var _copy_offset: Vector2 ## Offset in global coordinates from the move target.

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "_set_position" and _mode != Mode.SET:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "_add_position" and _mode != Mode.ADD:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_copy_target", "_copy_offset"] and _mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _target: Node2D
var _base: tBase
var _easing: tEasing
var _target_link: GDTargetLink
var _initial_global_position: Vector2
var _setup: tSetup

func _ready() -> void:
	_setup = tSetup.new(self, true)
	_base._sprite.set_texture(preload("res://assets/textures/triggers/Move.svg"))
	_target = _base._target

func _update_target_link() -> void:
	_target_link._target = _base._target

func _start(_body: Node2D) -> void:
	if _easing._is_inactive():
		if _target != null:
			_initial_global_position = _target.global_position
		else:
			printerr("In ", name, ": _base._target is unset")

func _reset() -> void:
	if _target != null:
		_target.global_position = _initial_global_position
	else:
		printerr("In ", name, ": _target is unset")

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(_easing._weight):
		if _base._target != null:
			var _weight_delta = _easing._get_weight_delta()
			match _mode:
				Mode.SET:
					_target.global_position += (owner.to_global(_set_position) - _initial_global_position) * _weight_delta
				Mode.ADD:
					_target.global_position += _add_position * _weight_delta
				Mode.COPY:
					if _copy_target != null:
						_target.global_position = lerp(_initial_global_position, _copy_target.global_position + _copy_offset, _easing._weight)
					else:
						printerr("In ", name, ": copy_target is unset!")
		else:
			printerr("In ", name, ": _target is unset")
	elif Engine.is_editor_hint() or LevelManager.in_editor:
		_target_link.position = Vector2.ZERO
		if Engine.is_editor_hint(): _base.position = Vector2.ZERO
