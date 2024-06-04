@tool
extends Node2D
class_name tCameraZoom

enum Mode {
	SET,
	MULTIPLY,
	DIVIDE,
}

@export var _mode: Mode = Mode.SET:
	set(value):
		_mode = value
		notify_property_list_changed()
@export var _set_zoom: Vector2 = Vector2.ONE
@export var _multiply_zoom: Vector2 = Vector2.ONE

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "_set_zoom" and _mode != Mode.SET:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "_multiply_zoom" and _mode != Mode.MULTIPLY and _mode != Mode.DIVIDE:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _player_camera: PlayerCamera
var _base: tBase
var _easing: tEasing
var _initial_zoom: Vector2

func _ready() -> void:
	TriggerSetup.setup(self, false)
	_base._sprite.set_texture(preload("res://assets/textures/triggers/CameraZoom.svg"))
	_player_camera = LevelManager.player_camera

func _start(_body: Node2D) -> void:
	if _easing._is_inactive():
		if _player_camera != null:
			_initial_zoom = _player_camera.zoom
		else:
			printerr("In ", name, ": _player_camera is unset")

func _reset() -> void:
	if _player_camera != null:
		_player_camera.zoom = _initial_zoom
	else:
		printerr("In ", name, ": _player_camera is unset")

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(_easing._weight):
		if _player_camera != null:
			var _weight_delta = _easing._get_weight_delta()
			match _mode:
				Mode.SET:
					_player_camera.zoom += (_set_zoom - _initial_zoom) * _weight_delta
				Mode.MULTIPLY:
					_player_camera.zoom -= (_initial_zoom - (_initial_zoom * _multiply_zoom)) * _weight_delta
				Mode.DIVIDE:
					_player_camera.zoom -= (_initial_zoom - (_initial_zoom / _multiply_zoom)) * _weight_delta
		else:
			printerr("In ", name, ": _player_camera is unset")
	elif Engine.is_editor_hint():
		_base.position = Vector2.ZERO
