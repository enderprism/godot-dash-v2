@tool
extends Node2D
class_name tGameplayRotate


@export_range(-360, 360, 0.01, "or_greater", "or_less") var _rotation_degrees: float
@export var _flip: bool

var _player: Player # Not useful in itself, but it provides autocompletion.
var _base: tBase
var _easing: tEasing
var _target_link: GDTargetLink
var _initial_global_rotation_degrees: float

func _ready() -> void:
	# Avoid re-instancing tBase, tEasing and TargetLink if they already exist
	if not has_node("tBase") and not has_node("tEasing") and not has_node("TargetLink"):
		# Init children
		_base = tBase.new(); _easing = tEasing.new();
		_target_link = load("res://scenes/components/game_components/GDTargetLink.tscn").instantiate()
		_base.name = "tBase"
		_easing.name = "tEasing"
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
		_update_target_link()
	# Signal connections
	if not _base.is_connected("body_entered", _start): _base.body_entered.connect(_start)
	if not _base.is_connected("body_entered", _easing._start): _base.body_entered.connect(_easing._start)
	if not _base.is_connected("target_changed", _update_target_link): _base.target_changed.connect(_update_target_link)
	_base._sprite.set_texture(preload("res://assets/textures/triggers/GameplayRotate.svg"))
	_player = LevelManager.player

func _update_target_link() -> void:
	_target_link._target = _player

func _start(_body: Node2D) -> void:
	if not _easing._tween.is_connected("finished", _instant_gameplay_rotate_conclude) and _easing._duration == 0.0: _easing._tween.finished.connect(_instant_gameplay_rotate_conclude)
	if _easing._is_inactive():
		if _player != null:
			_initial_global_rotation_degrees = _player._gameplay_rotation_degrees
		else:
			printerr("In ", name, ": _target is unset")

func _reset() -> void:
	if _player != null:
		_player._gameplay_rotation_degrees = _initial_global_rotation_degrees
	else:
		printerr("In ", name, ": _target is unset")

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(_easing._weight):
		if _player != null:
			var _weight_delta = _easing._get_weight_delta()
			_player._gameplay_rotation_degrees += (_rotation_degrees - _initial_global_rotation_degrees) * _weight_delta
		else:
			printerr("In ", name, ": _player is unset")
	elif Engine.is_editor_hint() or LevelManager.in_editor or get_tree().is_debugging_collisions_hint():
		_target_link.position = Vector2.ZERO
		_base._sprite.global_rotation_degrees = _rotation_degrees
		_base._sprite.scale = Vector2.ONE/4
		_base._sprite.flip_h = _flip
		if Engine.is_editor_hint(): _base.position = Vector2.ZERO

func _instant_gameplay_rotate_conclude() -> void:
	if _player._gameplay_rotation_degrees != _rotation_degrees:
		_player.velocity = Vector2(_player.velocity.rotated(-_player._gameplay_rotation).x, 0.0).rotated(_player._gameplay_rotation)
	_player._horizontal_direction = 1 if not _flip else -1