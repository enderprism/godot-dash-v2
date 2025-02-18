@tool
extends Node2D
class_name MoveTrigger

enum Mode {
	SET,
	ADD,
	COPY,
}

@export var mode: Mode = Mode.ADD:
	set(value):
		mode = value
		notify_property_list_changed()
@export var _set_position: Vector2
@export var _add_position: Vector2
@export var _copy_target: Node2D
@export var _copy_offset: Vector2 ## Offset in global coordinates from the move target.

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "_set_position" and mode != Mode.SET:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "_add_position" and mode != Mode.ADD:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_copy_target", "_copy_offset"] and mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var base: TriggerBase
var easing: TriggerEasing
var target_link: TargetLink

var _targets: Array[Node]
var _initial_positions: Dictionary

func _ready() -> void:
	TriggerSetup.setup(self, true)
	base.sprite.set_texture(preload("res://assets/textures/triggers/Move.svg"))
	_targets = get_tree().get_nodes_in_group(base.target_group)

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(easing._weight):
		if not _targets.is_empty():
			var _weight_delta = easing.get_weight_delta()
			for _target in _targets:
				var _initial_global_position = _initial_positions[_target]
				match mode:
					Mode.SET:
						_target.global_position += (owner.to_global(_set_position) - _initial_global_position) * _weight_delta
					Mode.ADD:
						_target.global_position += _add_position * _weight_delta
					Mode.COPY:
						if _copy_target != null:
							_target.global_position = lerp(_initial_global_position, _copy_target.global_position + _copy_offset, easing._weight)
						elif LevelManager.in_editor and LevelManager.level_playing:
							printerr("In ", name, ": copy_target is unset!")
		elif LevelManager.in_editor and LevelManager.level_playing:
			printerr("In ", name, ": _target is unset")
	elif Engine.is_editor_hint() or LevelManager.in_editor:
		target_link.position = Vector2.ZERO
		if Engine.is_editor_hint(): base.position = Vector2.ZERO

func update_target_link() -> void:
	target_link.target = _targets[0]

func start(_body: Node2D) -> void:
	if easing.is_inactive():
		if not _targets.is_empty():
			for _target in _targets:
				_initial_positions[_target] = _target.global_position
		elif LevelManager.in_editor and LevelManager.level_playing:
			printerr("In ", name, ": base._target is unset")

func reset() -> void:
	if not _targets.is_empty():
		for _target in _targets:
			_target.global_position = _initial_positions[_target]
	elif LevelManager.in_editor and LevelManager.level_playing:
		printerr("In ", name, ": _target is unset")