@tool
extends Node2D
class_name CameraOffsetTrigger

enum Mode {
	SET,
	ADD,
}

@export var mode: Mode = Mode.SET:
	set(value):
		mode = value
		notify_property_list_changed()
@export var offset: Vector2
@export var from_center: bool

var base: TriggerBase
var easing: EasingComponent

var _player_camera: PlayerCamera:
	get(): return LevelManager.player_camera if not Engine.is_editor_hint() else null
var _initial_offset: Vector2

func _ready() -> void:
	TriggerSetup.setup(self)
	base.sprite.set_texture(preload("res://assets/textures/triggers/CameraOffset.svg"))

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not easing.is_inactive():
		if _player_camera != null:
			if from_center:
				_player_camera.additional_offset_multiplier = _player_camera.additional_offset_multiplier.lerp(Vector2.ZERO, easing.weight)
			else:
				_player_camera.additional_offset_multiplier = _player_camera.additional_offset_multiplier.lerp(Vector2.ONE, easing.weight)
			match mode:
				Mode.SET:
					_player_camera.additional_offset += (offset - _initial_offset) * easing.weight_delta
				Mode.ADD:
					_player_camera.additional_offset += offset * easing.weight_delta
		else:
			printerr("In ", name, ": _player_camera is unset")
	elif Engine.is_editor_hint():
		base.position = Vector2.ZERO

func start(_body: Node2D) -> void:
	if easing.is_inactive():
		if _player_camera != null:
			_initial_offset = _player_camera.additional_offset
		else:
			printerr("In ", name, ": base._player_camera is unset")

func reset() -> void:
	if _player_camera != null:
		_player_camera.offset = _initial_offset
	else:
		printerr("In ", name, ": _player_camera is unset")
