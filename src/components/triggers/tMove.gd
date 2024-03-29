@tool
extends Node2D
class_name tMove

enum Mode {
	ABSOLUTE,
	RELATIVE,
	COPY,
}

@export var _mode: Mode = Mode.ABSOLUTE:
	set(value):
		_mode = value
		notify_property_list_changed()
@export var _absolute_position: Vector2
@export var _relative_offset: Vector2
@export var _copy_target: Node2D
@export var _copy_offset: Vector2 ## Offset in global coordinates from the move target.

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "_absolute_position" and _mode != Mode.ABSOLUTE:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name == "_relative_offset" and _mode != Mode.RELATIVE:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_copy_target", "_copy_offset"] and _mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _base: tBase
var _easing: tEasing
var _target_link: GDTargetLink
var _initial_global_position: Vector2

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
	if not is_connected("_base.body_entered", _start): _base.body_entered.connect(_start)
	if not is_connected("_base.body_entered", _easing._start): _base.body_entered.connect(_easing._start)
	if not is_connected("_base.target_changed", _update_target_link): _base.target_changed.connect(_update_target_link)
	_base._sprite.set_texture(preload("res://assets/textures/triggers/Move.svg"))

func _update_target_link() -> void:
	_target_link._target = _base._target

func _start(_body: Node2D) -> void:
	if _easing._weight == 0.0:
		_initial_global_position = _base._target.global_position

func _reset() -> void:
	_base._target.global_position = _initial_global_position

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(_easing._weight):
		var _weight_delta = _easing._get_weight_delta()
		match _mode:
			Mode.ABSOLUTE:
				_base._target.global_position += (owner.to_global(_absolute_position) - _initial_global_position) * _weight_delta
			Mode.RELATIVE:
				_base._target.global_position += _relative_offset * _weight_delta
			Mode.COPY:
				if _copy_target != null:
					_base._target.global_position = lerp(_initial_global_position, _copy_target.global_position + _copy_offset, _easing._weight)
					# _base._target.global_position += (_copy_target.global_position - _initial_global_position + _copy_offset) * _weight_delta
				else:
					printerr("In ", name, ": copy_target is unset!")
	elif Engine.is_editor_hint() or LevelManager.in_editor:
		_target_link.position = Vector2.ZERO
