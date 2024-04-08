@tool
extends Node2D
class_name tGameplayRotate


@export_range(-360, 360, 0.01, "or_greater", "or_less", "degrees" ) var _rotation_degrees: float
@export var _flip: bool
@export var _reverse: bool
@export var _set_velocity: bool:
	set(value):
		_set_velocity = value
		notify_property_list_changed()
# @export var _new_velocity: Vector2

func _validate_property(property: Dictionary) -> void:
	if property.name == "_new_velocity" and not _set_velocity:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _player: Player # Not useful in itself, but it provides autocompletion.
var _base: tBase
var _easing: tEasing
var _initial_global_rotation_degrees: float
var _setup: tSetup

func _ready() -> void:
	_setup = tSetup.new(self, false)
	_base._sprite.set_texture(preload("res://assets/textures/triggers/GameplayRotate.svg"))
	_player = LevelManager.player

func _start(_body: Node2D) -> void:
	_player._gravity_multiplier = abs(_player._gravity_multiplier) * 1 if not _flip else -1
	_player._horizontal_direction = 1 if not _reverse else -1
	_initial_global_rotation_degrees = _player._gameplay_rotation_degrees
	if _easing._duration == 0.0:
		_player._gameplay_rotation_degrees = _rotation_degrees
		_player.velocity = _player.velocity.rotated(deg_to_rad(_rotation_degrees))

func _reset() -> void:
	if _player != null:
		_player._gameplay_rotation_degrees = _initial_global_rotation_degrees
	else:
		printerr("In ", name, ": _target is unset")

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(_easing._weight):
		if _player != null:
			if _easing._duration > 0.0:
				var _weight_delta: float = _easing._get_weight_delta()
				var _rotation_delta: float = (_rotation_degrees - _initial_global_rotation_degrees) * _weight_delta
				_player._gameplay_rotation_degrees += _rotation_delta
				_player.velocity = _player.velocity.rotated(deg_to_rad(_rotation_delta))
		else:
			printerr("In ", name, ": _player is unset")
	if Engine.is_editor_hint() or LevelManager.in_editor or get_tree().is_debugging_collisions_hint():
		_base._sprite.global_rotation_degrees = _rotation_degrees
		_base._sprite.scale = Vector2.ONE/4
		_base._sprite.flip_h = _reverse
		_base._sprite.flip_v = _flip
		if Engine.is_editor_hint(): _base.position = Vector2.ZERO
