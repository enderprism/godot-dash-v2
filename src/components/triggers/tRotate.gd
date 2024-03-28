@tool
extends Node2D
class_name tRotate

enum Mode {
	ADD,
	SET,
	COPY,
}

@export var _mode: Mode = Mode.ADD:
	set(value):
		_mode = value
		notify_property_list_changed()
@export_range(-360, 360, 0.01, "or_greater", "or_less") var _set_rotation_degrees: float
@export_range(-360, 360, 0.01, "or_greater", "or_less") var _add_rotation_degrees: float
@export var _copy_target: Node2D
@export_range(-360, 360, 0.01, "or_greater", "or_less") var _copy_offset: float ## Offset in global coordinates from the move target.

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "_set_rotation_degrees" and _mode != Mode.SET:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "_add_rotation_degrees" and _mode != Mode.ADD:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_copy_target", "_copy_offset"] and _mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _target: Node2D # Not useful in itself, but it provides autocompletion.
var _base: tBase
var _easing: tEasing
var _target_link: GDTargetLink
var _initial_global_rotation_degrees: float

func _ready() -> void:
	# Avoid re-instancing tBase, tEasing and TargetLink if they already exist
	if not has_node("tBase") and not has_node("tEasing") and not has_node("TargetLink"):
		# Init children
		_base = tBase.new(); _easing = tEasing.new();
		_target_link = load("res://scenes/components/game_components/GDTargetLink.tscn").instantiate()
		_base.name = "tBase"
		_easing.name = "tEasing"
		# Add children to the tree
		add_child(_target_link)
		add_child(_easing)
		add_child(_base)
		# Fix to make them show in the Scene Tree (in the Godot UI)
		_easing.set_owner(get_parent()); _base.set_owner(get_parent()); _target_link.set_owner(get_parent());
	else:
		_base = $tBase
		_easing = $tEasing
		_target_link = $TargetLink
		_update_target_link()
	# Signal connections
	if not _base.is_connected("body_entered", _start): _base.body_entered.connect(_start)
	if not _base.is_connected("body_entered", _easing._start): _base.body_entered.connect(_easing._start)
	if not _base.is_connected("target_changed", _update_target_link): _base.target_changed.connect(_update_target_link)
	_base._sprite.set_texture(preload("res://assets/textures/triggers/Rotate.svg"))
	_target = _base._target

func _update_target_link() -> void:
	_target_link._target = _base._target

func _start(_body: Node2D) -> void:
	if _easing._is_inactive():
		if _target != null:
			_initial_global_rotation_degrees = _target.global_rotation_degrees
		else:
			printerr("In ", name, ": _target is unset")

func _reset() -> void:
	if _target != null:
		_target.global_rotation_degrees = _initial_global_rotation_degrees
	else:
		printerr("In ", name, ": _target is unset")

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(_easing._weight):
		if _target != null:
			var _weight_delta = _easing._get_weight_delta()
			match _mode:
				Mode.SET:
					_target.global_rotation_degrees += (_set_rotation_degrees - _initial_global_rotation_degrees) * _weight_delta
				Mode.ADD:
					_target.global_rotation_degrees += _add_rotation_degrees * _weight_delta
				Mode.COPY:
					if _copy_target != null:
						_target.global_rotation_degrees = lerp(_initial_global_rotation_degrees, _copy_target.global_rotation_degrees + _copy_offset, _easing._weight)
					else:
						printerr("In ", name, ": copy_target is unset!")
		else:
			printerr("In ", name, ": _target is unset")
	elif Engine.is_editor_hint() or LevelManager.in_editor:
		_target_link.position = Vector2.ZERO
		if Engine.is_editor_hint(): _base.position = Vector2.ZERO