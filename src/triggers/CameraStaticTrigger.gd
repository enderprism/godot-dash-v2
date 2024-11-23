@tool
extends Node2D
class_name CameraStaticTrigger

enum Mode {
	ENTER,
	EXIT,
}

@export var mode: Mode = Mode.ENTER:
	set(value):
		mode = value
		notify_property_list_changed()
@export var ignore_x: bool
@export var ignore_y: bool

# Hide unneeded elements in the inspector
# func _validate_property(property: Dictionary) -> void:

var base: TriggerBase
var easing: TriggerEasing
var target_link: TargetLink


var _player: Player:
	get(): return LevelManager.player if not Engine.is_editor_hint() else null
var _player_camera: PlayerCamera:
	get(): return LevelManager.player_camera if not Engine.is_editor_hint() else null
var _target: Node2D
var _initial_global_position: Vector2

func _ready() -> void:
	TriggerSetup.setup(self, true)
	base.sprite.set_texture(preload("res://assets/textures/triggers/CameraStatic.svg"))
	_target = base._target

func update_target_link() -> void:
	target_link.target = base._target

func start(_body: Node2D) -> void:
	easing._tween.disconnect("finished", _exit_static_end)
	if mode == Mode.EXIT: easing._tween.finished.connect(_exit_static_end)
	if easing._is_inactive():
		if _player_camera != null:
			if mode == Mode.ENTER:
				if not ignore_x:
					_player_camera._static.x = 1
				if not ignore_y:
					_player_camera._static.y = 1
					_player_camera.limit_bottom = 10000000
			elif mode == Mode.EXIT:
				# We want to have the vertical camera aligment during the transition
				if not ignore_y:
					_player_camera._static.y = 0
					_player_camera.limit_bottom = _player_camera.DEFAULT_LIMIT_BOTTOM
			_initial_global_position = _player_camera.global_position
		else:
			printerr("In ", name, ": _player_camera is unset")

func _exit_static_end() -> void:
	if not ignore_x:
		_player_camera._static.x = 0

func reset() -> void:
	if _player_camera != null:
		_player_camera.global_position = _initial_global_position
	else:
		printerr("In ", name, ": _player_camera is unset")

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not easing._is_inactive():
		if _player_camera != null:
			match mode:
				Mode.ENTER:
					if not ignore_x:
						_player_camera.global_position.x = lerp(
							_player_camera.global_position.x,
							_target.global_position.x,
							easing._weight)
					if not ignore_y:
						_player_camera.global_position.y = lerp(
							_player_camera.global_position.y,
							_target.global_position.y,
							easing._weight)
				Mode.EXIT:
					if not ignore_x:
						_player_camera.global_position.x = lerp(
							_player_camera.global_position.x,
							_player.global_position.x + _player_camera.position_offset.x,
							easing._weight)
					# if not ignore_y:
					# 	_player_camera.global_position.y = lerp(
					# 		_player_camera.global_position.y,
					# 		_player.global_position.y + _player_camera.position_offset.y,
					# 		easing._weight)
		else:
			printerr("In ", name, ": _player_camera is unset")
	elif Engine.is_editor_hint():
		base.position = Vector2.ZERO
