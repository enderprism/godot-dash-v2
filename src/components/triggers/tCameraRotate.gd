@tool
extends Node2D
class_name tCameraRotate

enum Mode {
	SET,
	ADD,
	COPY,
}

@export var _mode: Mode = Mode.SET:
	set(value):
		_mode = value
		notify_property_list_changed()
@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees") var _set_rotation_degrees: float
@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees") var _add_rotation_degrees: float
@export var _copy_target: Node2D
@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees") var _copy_offset: float ## Offset in global coordinates from the move target.

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "_set_rotation_degrees" and _mode != Mode.SET:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "_add_rotation_degrees" and _mode != Mode.ADD:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_copy_target", "_copy_offset"] and _mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _player_camera: PlayerCamera
var _base: tBase
var _easing: tEasing
var _initial_global_rotation_degrees: float

func _ready() -> void:
	# Avoid re-instancing tBase, tEasing and TargetLink if they already exist
	if not has_node("tBase") and not has_node("tEasing") and not has_node("TargetLink"):
		# Init children
		_base = tBase.new(); _easing = tEasing.new();
		_base.name = "tBase"
		_easing.name = "tEasing"
		# Add children to the tree
		add_child(_easing)
		add_child(_base)
		# Fix to make them show in the Scene Tree (in the Godot UI)
		_easing.set_owner(get_parent()); _base.set_owner(get_parent());
	else:
		_base = $tBase
		_easing = $tEasing
	# Signal connections
	if not _base.is_connected("body_entered", _start): _base.body_entered.connect(_start)
	if not _base.is_connected("body_entered", _easing._start): _base.body_entered.connect(_easing._start)
	_base._sprite.set_texture(preload("res://assets/textures/triggers/CameraRotate.svg"))
	_player_camera = LevelManager.player_camera

func _start(_body: Node2D) -> void:
	if _easing._is_inactive():
		if _player_camera != null:
			_initial_global_rotation_degrees = _player_camera.global_rotation_degrees
		else:
			printerr("In ", name, ": _player_camera is unset")

func _reset() -> void:
	if _player_camera != null:
		_player_camera.global_rotation_degrees = _initial_global_rotation_degrees
	else:
		printerr("In ", name, ": _player_camera is unset")

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(_easing._weight):
		if _player_camera != null:
			var _weight_delta = _easing._get_weight_delta()
			match _mode:
				Mode.SET:
					_player_camera.global_rotation_degrees += (_set_rotation_degrees - _initial_global_rotation_degrees) * _weight_delta
				Mode.ADD:
					_player_camera.global_rotation_degrees += _add_rotation_degrees * _weight_delta
				Mode.COPY:
					if _copy_target != null:
						_player_camera.global_rotation_degrees = lerp(_initial_global_rotation_degrees, _copy_target.global_rotation_degrees + _copy_offset, _easing._weight)
					else:
						printerr("In ", name, ": copy_player_camera is unset!")
		else:
			printerr("In ", name, ": _player_camera is unset")
	elif Engine.is_editor_hint():
		_base.position = Vector2.ZERO
