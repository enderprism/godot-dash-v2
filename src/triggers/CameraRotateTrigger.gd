@tool
extends Node2D
class_name CameraRotateTrigger

enum Mode {
	SET,
	ADD,
	COPY,
}

@export var mode: Mode = Mode.SET:
	set(value):
		mode = value
		notify_property_list_changed()
@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees") var _set_rotation_degrees: float
@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees") var _add_rotation_degrees: float
@export var _copy_target: Node2D
@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees") var _copy_offset: float ## Offset in global coordinates from the move target.

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "_set_rotation_degrees" and mode != Mode.SET:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "_add_rotation_degrees" and mode != Mode.ADD:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_copy_target", "_copy_offset"] and mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var base: TriggerBase
var easing: TriggerEasing

var _player_camera: PlayerCamera:
	get(): return LevelManager.player_camera if not Engine.is_editor_hint() else null
var _initial_global_rotation_degrees: float

func _ready() -> void:
	TriggerSetup.setup(self)
	base.sprite.set_texture(preload("res://assets/textures/triggers/CameraRotate.svg"))

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(easing._weight):
		if _player_camera != null:
			var _weight_delta = easing.get_weight_delta()
			match mode:
				Mode.SET:
					_player_camera.global_rotation_degrees += (_set_rotation_degrees - _initial_global_rotation_degrees) * _weight_delta
				Mode.ADD:
					_player_camera.global_rotation_degrees += _add_rotation_degrees * _weight_delta
				Mode.COPY:
					if _copy_target != null:
						_player_camera.global_rotation_degrees = lerp(_initial_global_rotation_degrees, _copy_target.global_rotation_degrees + _copy_offset, easing._weight)
					else:
						printerr("In ", name, ": copy_player_camera is unset!")
		else:
			printerr("In ", name, ": _player_camera is unset")
	elif Engine.is_editor_hint():
		base.position = Vector2.ZERO

func start(_body: Node2D) -> void:
	if easing.is_inactive():
		if _player_camera != null:
			_initial_global_rotation_degrees = _player_camera.global_rotation_degrees
		else:
			printerr("In ", name, ": _player_camera is unset")

func reset() -> void:
	if _player_camera != null:
		_player_camera.global_rotation_degrees = _initial_global_rotation_degrees
	else:
		printerr("In ", name, ": _player_camera is unset")