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
@export var zoom := Vector2.ONE

var base: TriggerBase

var _player_camera: PlayerCamera:
	get(): return LevelManager.player_camera if not Engine.is_editor_hint() else null
var easing: TriggerEasing
var _initial_zoom: Vector2

func _ready() -> void:
	TriggerSetup.setup(self)
	base.sprite.set_texture(preload("res://assets/textures/triggers/CameraZoom.svg"))

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not easing.is_inactive():
		if _player_camera != null:
			match mode:
				Mode.SET:
					_player_camera.zoom += (zoom - _initial_zoom) * easing.weight_delta * PlayerCamera.DEFAULT_ZOOM
				Mode.MULTIPLY:
					_player_camera.zoom -= (_initial_zoom - (_initial_zoom * zoom)) * easing.weight_delta * PlayerCamera.DEFAULT_ZOOM
				Mode.DIVIDE:
					_player_camera.zoom -= (_initial_zoom - (_initial_zoom / zoom)) * easing.weight_delta * PlayerCamera.DEFAULT_ZOOM
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
