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
	TriggerSetup.setup(self, TriggerSetup.ADD_TARGET_LINK | TriggerSetup.ADD_EASING)
	base.sprite.set_texture(preload("res://assets/textures/triggers/CameraStatic.svg"))
	update_target_link()


func update_target_link() -> void:
	target_link.target = base._target


func start(_body: Node2D) -> void:
	_target = base._target
	# if LevelManager.active_camera_static != null and LevelManager.active_camera_static != self:
	# 	LevelManager.active_camera_static.easing._tween.pause()
	# 	LevelManager.active_camera_static.easing._tween.custom_step(easing.duration)
	# 	LevelManager.active_camera_static.easing.weight = 1.0
	# 	LevelManager.active_camera_static.easing._tween.finished.emit()
	# LevelManager.active_camera_static = self
	if not easing.is_inactive():
		return

	if _player_camera == null:
		printerr("In ", name, ": _player_camera is unset")
		return
	
	_initial_global_position = _player_camera.global_position
	
	if mode == Mode.ENTER:
		if not ignore_x:
			_player_camera.movement_factor.x = 0
			_player_camera.offset_factor.x = 0

			if easing.duration == 0.0:
				_player_camera.global_position.x = _target.global_position.x
		if not ignore_y:
			_player_camera.movement_factor.y = 0
			_player_camera.offset_factor.y = 0
			
			if easing.duration == 0.0:
				_player_camera.global_position.y = _target.global_position.y
	# elif mode == Mode.EXIT:
	# 	if not ignore_y:
	# 		_player_camera.movement_factor.y = 1
	# 		_player_camera.offset_factor.y = 1
	#
	# 		if easing.duration == 0.0:
	# 			_player_camera.global_position.y = _player.global_position.y


func reset() -> void:
	if _player_camera != null:
		_player_camera.global_position = _initial_global_position
	else:
		printerr("In ", name, ": _player_camera is unset")


func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not easing.is_inactive():
		if _player_camera != null:
			match mode:
				Mode.ENTER:
					if not ignore_x:
						_player_camera.global_position.x = lerpf(
							_initial_global_position.x,
							_target.global_position.x,
							easing.weight)
					if not ignore_y:
						_player_camera.global_position.y = lerpf(
							_initial_global_position.y,
							_target.global_position.y,
							easing.weight)
				Mode.EXIT:
					if not ignore_x:
						_player_camera.offset_factor.x = lerpf(
							0.0,
							1.0,
							easing.weight)
						_player_camera.movement_factor.x = lerpf(
							0.0,
							1.0,
							easing.weight)
						_player_camera.global_position.x = lerpf(
							_initial_global_position.x,
							_player.global_position.x,
							easing.weight)
					if not ignore_y:
						_player_camera.offset_factor.y = lerpf(
							0.0,
							1.0,
							easing.weight)
						_player_camera.movement_factor.y = lerpf(
							0.0,
							1.0,
							easing.weight)
						_player_camera.global_position.y = lerpf(
							_initial_global_position.y,
							_player.global_position.y,
							easing.weight)
		else:
			printerr("In ", name, ": _player_camera is unset")
	elif Engine.is_editor_hint():
		base.position = Vector2.ZERO
