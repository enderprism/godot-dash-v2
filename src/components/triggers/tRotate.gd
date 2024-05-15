@tool
extends Node2D
class_name tRotate

enum Mode {
	ADD,
	SET,
	COPY,
}

const TRIGGER_TYPE = ITC.TriggerType.ROTATE

@export var _rotate_around_self: bool:
	set(value):
		_rotate_around_self = value
		notify_property_list_changed()
@export var _rotation_center: Node2D
@export var _mode: Mode = Mode.ADD:
	set(value):
		_mode = value
		notify_property_list_changed()
@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees") var _set_rotation_degrees: float
@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees") var _add_rotation_degrees: float
@export var _copy_target: Node2D
@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees") var _copy_offset: float ## Offset in global coordinates from the rotation target.

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "_set_rotation_degrees" and _mode != Mode.SET:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "_add_rotation_degrees" and _mode != Mode.ADD:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_copy_target", "_copy_offset"] and _mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "_rotation_center" and _rotate_around_self:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _targets: Array[Node] ## Array of all the [Node2D] in a group.
var _initial_rotations: Array[float] ## Rotation in degrees for every [Node2D] in [member _targets]
var _initial_distances: Array[Vector2] ## Distance from the [member _rotation_center] for every [Node2D] in [member _targets]
var _base: tBase
var _easing: tEasing
var _target_link: GDTargetLink

func _ready() -> void:
	TriggerSetup.setup(self, true)
	_base._sprite.set_texture(preload("res://assets/textures/triggers/Rotate.svg"))
	_targets = get_tree().get_nodes_in_group(_base._target_group)

func _update_target_link() -> void:
	_target_link._target = _base._target

func _start(_body: Node2D) -> void:
	if _easing._is_inactive():
		if not _targets.is_empty():
			for i in range(len(_targets)):
				_initial_rotations.resize(len(_targets))
				_initial_rotations[i] = _targets[i].global_rotation_degrees
				if not _rotate_around_self: _initial_distances.insert(i, _targets[i].global_position - _rotation_center.global_position)
		else:
			printerr("In ", name, ": _target is unset")

func _reset() -> void:
	if not _targets.is_empty():
		for i in range(len(_targets)):
			_targets[i].global_rotation_degrees = _initial_rotations[i]
	else:
		printerr("In ", name, ": _target is unset")

func _refresh_distance(i: int) -> void:
	if not _targets.is_empty():
		_initial_distances[i] = _targets[i].global_position - _rotation_center.global_position

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(_easing._weight):
		if not _targets.is_empty():
			var _weight_delta = _easing._get_weight_delta()
			for i in range(len(_targets)):
				var _target: Node2D = _targets[i]
				var _initial_global_rotation_degrees: float = _initial_rotations[i]
				var _initial_distance: Vector2
				if not _rotate_around_self:
					_initial_distance = _initial_distances[i]
				var _rotation_delta: float
				match _mode:
					Mode.SET:
						_rotation_delta = (_set_rotation_degrees - _initial_global_rotation_degrees) * _weight_delta
					Mode.ADD:
						_rotation_delta = _add_rotation_degrees * _weight_delta
					Mode.COPY:
						if _copy_target != null:
							_target.global_rotation_degrees = lerp(
								_initial_global_rotation_degrees,
								_copy_target.global_rotation_degrees + _copy_offset,
								_easing._weight)
						else:
							printerr("In ", name, ": copy_target is unset!")
						# Escape the current loop iteration to avoid adding the rotation delta, even if it's null.
						continue
				# Add the rotation delta
				_target.global_rotation_degrees += _rotation_delta
				ITC.set_data(self, _target, _rotation_delta)
				if not _rotate_around_self:
					_target.global_position += _initial_distance.rotated(deg_to_rad(_rotation_delta)) - _initial_distance
					_refresh_distance(i)
		else:
			printerr("In ", name, ": _target is unset")
	elif Engine.is_editor_hint() or LevelManager.in_editor:
		_target_link.position = Vector2.ZERO
		if Engine.is_editor_hint(): _base.position = Vector2.ZERO
