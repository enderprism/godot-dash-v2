@tool
extends Node2D
class_name tCameraOffset

enum Mode {
	SET,
	ADD,
}

@export var mode: Mode = Mode.SET:
	set(value):
		mode = value
		notify_property_list_changed()
@export var _set_offset: Vector2
@export var _add_offset: Vector2
@export var _from_center: bool

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "_set_offset" and mode != Mode.SET:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "_add_offset" and mode != Mode.ADD:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _player_camera: PlayerCamera
var base: tBase
var easing: tEasing
var _initial_offset: Vector2

func _ready() -> void:
	TriggerSetup.setup(self, false)
	base.sprite.set_texture(preload("res://assets/textures/triggers/CameraOffset.svg"))
	_player_camera = LevelManager.player_camera

func _start(_body: Node2D) -> void:
	if easing._is_inactive():
		if _player_camera != null:
			_initial_offset = _player_camera._tOffset
		else:
			printerr("In ", name, ": base._player_camera is unset")

func _reset() -> void:
	if _player_camera != null:
		_player_camera.offset = _initial_offset
	else:
		printerr("In ", name, ": _player_camera is unset")

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(easing._weight):
		if _player_camera != null:
			var _weight_delta = easing._get_weight_delta()
			if _from_center:
				_player_camera._tOffset_multiplier = _player_camera._tOffset_multiplier.lerp(Vector2.ZERO, easing._weight)
			else:
				_player_camera._tOffset_multiplier = _player_camera._tOffset_multiplier.lerp(Vector2.ONE, easing._weight)
			match mode:
				Mode.SET:
					_player_camera._tOffset += (_set_offset - _initial_offset) * _weight_delta
				Mode.ADD:
					_player_camera._tOffset += _add_offset * _weight_delta
		else:
			printerr("In ", name, ": _player_camera is unset")
	elif Engine.is_editor_hint():
		base.position = Vector2.ZERO
