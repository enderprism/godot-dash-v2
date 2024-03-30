@tool
extends Node2D
class_name tCameraStatic

enum Mode {
	ENTER,
	EXIT,
}

@export var _mode: Mode = Mode.ENTER:
	set(value):
		_mode = value
		notify_property_list_changed()
@export var _ignore_x: bool
@export var _ignore_y: bool

# Hide unneeded elements in the inspector
# func _validate_property(property: Dictionary) -> void:

var _player_camera: PlayerCamera
var _player: Player
var _target_link: GDTargetLink
var _target: Node2D
var _base: tBase
var _easing: tEasing
var _initial_global_position: Vector2

func _ready() -> void:
	# Avoid re-instancing tBase, tEasing and TargetLink if they already exist
	if not has_node("tBase") and not has_node("tEasing") and not has_node("TargetLink"):
		# Init children
		_base = tBase.new(); _easing = tEasing.new();
		_base.name = "tBase"
		_easing.name = "tEasing"
		_target_link = load("res://scenes/components/game_components/GDTargetLink.tscn").instantiate()
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
	# Signal connections
	if not _base.is_connected("body_entered", _start): _base.body_entered.connect(_start)
	if not _base.is_connected("body_entered", _easing._start): _base.body_entered.connect(_easing._start)
	if not _base.is_connected("target_changed", _update_target_link): _base.target_changed.connect(_update_target_link)
	_base._sprite.set_texture(preload("res://assets/textures/triggers/CameraStatic.svg"))
	_player_camera = LevelManager.player_camera
	_player = LevelManager.player
	_target = _base._target

func _update_target_link() -> void:
	_target_link._target = _base._target

func _start(_body: Node2D) -> void:
	_easing._tween.disconnect("finished", _exit_static_end)
	if _mode == Mode.EXIT: _easing._tween.finished.connect(_exit_static_end)
	if _easing._is_inactive():
		if _player_camera != null:
			if _mode == Mode.ENTER:
				if not _ignore_x:
					_player_camera._static.x = 1
				if not _ignore_y:
					_player_camera._static.y = 1
					_player_camera.limit_bottom = 10000000
			elif _mode == Mode.EXIT:
				# We want to have the vertical camera aligment during the transition
				if not _ignore_y:
					_player_camera._static.y = 0
					_player_camera.limit_bottom = _player_camera.DEFAULT_LIMIT_BOTTOM
			_initial_global_position = _player_camera.global_position
		else:
			printerr("In ", name, ": _player_camera is unset")

func _exit_static_end() -> void:
	if not _ignore_x:
		_player_camera._static.x = 0

func _reset() -> void:
	if _player_camera != null:
		_player_camera.global_position = _initial_global_position
	else:
		printerr("In ", name, ": _player_camera is unset")

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not _easing._is_inactive():
		if _player_camera != null:
			match _mode:
				Mode.ENTER:
					if not _ignore_x:
						_player_camera.global_position.x = lerp(
							_player_camera.global_position.x,
							_target.global_position.x,
							_easing._weight)
					if not _ignore_y:
						_player_camera.global_position.y = lerp(
							_player_camera.global_position.y,
							_target.global_position.y,
							_easing._weight)
				Mode.EXIT:
					if not _ignore_x:
						_player_camera.global_position.x = lerp(
							_player_camera.global_position.x,
							_player.global_position.x + _player_camera._position_offset.x,
							_easing._weight)
					# if not _ignore_y:
					# 	_player_camera.global_position.y = lerp(
					# 		_player_camera.global_position.y,
					# 		_player.global_position.y + _player_camera._position_offset.y,
					# 		_easing._weight)
		else:
			printerr("In ", name, ": _player_camera is unset")
	elif Engine.is_editor_hint():
		_base.position = Vector2.ZERO
