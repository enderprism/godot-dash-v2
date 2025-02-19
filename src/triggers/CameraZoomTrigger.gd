@tool
extends Node2D
class_name CameraZoomTrigger

enum Mode {
	SET,
	MULTIPLY,
	DIVIDE,
}

@export var mode: Mode = Mode.SET:
	set(value):
		mode = value
		notify_property_list_changed()
@export var set_zoom := Vector2.ONE
@export var multiply_zoom := Vector2.ONE

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "set_zoom" and mode != Mode.SET:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "multiply_zoom" and mode != Mode.MULTIPLY and mode != Mode.DIVIDE:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var base: TriggerBase

var _player_camera: PlayerCamera:
	get(): return LevelManager.player_camera if not Engine.is_editor_hint() else null
var easing: TriggerEasing
var _initial_zoom: Vector2

func _ready() -> void:
	TriggerSetup.setup(self, false)
	base.sprite.set_texture(preload("res://assets/textures/triggers/CameraZoom.svg"))

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(easing._weight):
		if _player_camera != null:
			var _weight_delta = easing.get_weight_delta()
			match mode:
				Mode.SET:
					_player_camera.zoom += (set_zoom - _initial_zoom) * _weight_delta * PlayerCamera.DEFAULT_ZOOM
				Mode.MULTIPLY:
					_player_camera.zoom -= (_initial_zoom - (_initial_zoom * multiply_zoom)) * _weight_delta * PlayerCamera.DEFAULT_ZOOM
				Mode.DIVIDE:
					_player_camera.zoom -= (_initial_zoom - (_initial_zoom / multiply_zoom)) * _weight_delta * PlayerCamera.DEFAULT_ZOOM
		else:
			printerr("In ", name, ": _player_camera is unset")
	elif Engine.is_editor_hint():
		base.position = Vector2.ZERO

func start(_body: Node2D) -> void:
	if easing.is_inactive():
		if _player_camera != null:
			_initial_zoom = _player_camera.zoom
		else:
			printerr("In ", name, ": _player_camera is unset")

func reset() -> void:
	if _player_camera != null:
		_player_camera.zoom = _initial_zoom
	else:
		printerr("In ", name, ": _player_camera is unset")