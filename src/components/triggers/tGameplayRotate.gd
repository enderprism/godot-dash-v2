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
@export var _new_velocity: Vector2

func _validate_property(property: Dictionary) -> void:
	if property.name == "_new_velocity" and not _set_velocity:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _player: Player # Not useful in itself, but it provides autocompletion.
var _base: tBase
var _easing: tEasing
var _initial_global_rotation_degrees: float

func _ready() -> void:
	# Avoid re-instancing tBase, tEasing and TargetLink if they already exist
	if not has_node("tBase") and not has_node("tEasing") and not has_node("TargetLink") and not has_node("BlackPad"):
		# Init children
		_base = tBase.new(); _easing = tEasing.new();
		_base.name = "tBase"
		_easing.name = "tEasing"
		# Add children to the tree
		add_child(_easing)
		add_child(_base)
		# Fix to make it show in the Scene Tree (in the Godot UI)
		_base.set_owner(get_parent()); _easing.set_owner(get_parent());
		_easing._duration = 0.0
	else:
		_base = $tBase
		_easing = $tEasing
	# Signal connections
	if not _base.is_connected("body_entered", _start): _base.body_entered.connect(_start)
	if not _base.is_connected("body_entered", _easing._start): _base.body_entered.connect(_easing._start)
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
