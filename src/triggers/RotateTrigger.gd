@tool
extends Node2D
class_name RotateTrigger

signal rotation_delta_changed(new_delta, target)

enum Mode {
	ADD,
	SET,
	COPY,
}

@export var _rotate_around_self: bool:
	set(value):
		_rotate_around_self = value
		notify_property_list_changed()
@export var _pivot: Node2D
@export var mode: Mode = Mode.ADD:
	set(value):
		mode = value
		notify_property_list_changed()
@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees") var _set_rotation_degrees: float
@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees") var _add_rotation_degrees: float
@export var _copy_target: Node2D
@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees") var _copy_offset: float ## Offset in global coordinates from the rotation target.

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "_set_rotation_degrees" and mode != Mode.SET:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "_add_rotation_degrees" and mode != Mode.ADD:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_copy_target", "_copy_offset"] and mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "_pivot" and _rotate_around_self:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var base: TriggerBase
var easing: TriggerEasing
var target_link: TargetLink

var _targets: Array[Node] ## Array of all the [Node2D] in a group.
var _initial_rotations: Dictionary ## Rotation in degrees for every [Node2D] in [member _targets]

func _ready() -> void:
	TriggerSetup.setup(self, TriggerSetup.ADD_TARGET_LINK | TriggerSetup.ADD_EASING)
	base.sprite.set_texture(preload("res://assets/textures/triggers/Rotate.svg"))
	_targets = get_tree().get_nodes_in_group(base.target_group)

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(easing._weight):
		if not _targets.is_empty():
			var _weight_delta = easing.get_weight_delta()
			for _target in _targets:
				var _initial_global_rotation_degrees: float = _initial_rotations[_target]
				var _rotation_delta: float
				match mode:
					Mode.SET:
						_rotation_delta = (_set_rotation_degrees - _initial_global_rotation_degrees) * _weight_delta
					Mode.ADD:
						_rotation_delta = _add_rotation_degrees * _weight_delta
					Mode.COPY:
						if _copy_target != null:
							_target.global_rotation_degrees = lerp(
								_initial_global_rotation_degrees,
								_copy_target.global_rotation_degrees + _copy_offset,
								easing._weight)
						elif LevelManager.in_editor and LevelManager.level_playing:
							printerr("In ", name, ": copy_target is unset!")
						# Escape the current loop iteration to avoid adding the rotation delta, even if it's null.
						continue
				# Add the rotation delta
				if _rotate_around_self:
					_target.global_rotation_degrees += _rotation_delta
				else:
					_target.global_rotation_degrees += _rotation_delta
					var position_relative_to_pivot: Vector2 = _target.global_position - _pivot.global_position
					var position_delta := position_relative_to_pivot.rotated(deg_to_rad(_rotation_delta)) - position_relative_to_pivot
					_target.global_position += position_delta
		elif LevelManager.in_editor and LevelManager.level_playing:
			printerr("In ", name, ": _target is unset")
	elif Engine.is_editor_hint() or LevelManager.in_editor:
		target_link.position = Vector2.ZERO
		if Engine.is_editor_hint(): base.position = Vector2.ZERO

func update_target_link() -> void:
	target_link.target = base._target

func start(_body: Node2D) -> void:
	if easing.is_inactive():
		if not _targets.is_empty():
			for _target in _targets:
				_initial_rotations[_target] = _target.global_rotation_degrees
		elif LevelManager.in_editor and LevelManager.level_playing:
			printerr("In ", name, ": _target is unset")

func reset() -> void:
	if not _targets.is_empty():
		for _target in _targets:
			_target.global_rotation_degrees = _initial_rotations[_target]
	elif LevelManager.in_editor and LevelManager.level_playing:
		printerr("In ", name, ": _target is unset")
