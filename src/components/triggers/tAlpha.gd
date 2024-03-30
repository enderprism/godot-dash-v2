@tool
extends Node2D
class_name tAlpha

enum Mode {
	SET,
	MULTIPLY,
	DIVIDE,
	COPY,
}

@export var _mode: Mode = Mode.SET:
	set(value):
		_mode = value
		notify_property_list_changed()
@export_range(0.0, 1.0, 0.01) var _alpha: float
@export var _copy_target: Node2D
@export_range(0.0, 1.0, 0.01, "or_greater") var _copy_multiplier: float

# Hide unneeded elements in the inspector
func _validate_property(property: Dictionary) -> void:
	if property.name == "_set_alpha" and _mode == Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	if property.name in ["_copy_target", "_copy_multiplier"] and _mode != Mode.COPY:
		property.usage = PROPERTY_USAGE_NO_EDITOR

var _target: Node2D # Not useful in itself, but it provides autocompletion.
var _base: tBase
var _easing: tEasing
var _target_link: GDTargetLink
var _initial_alpha: float

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
	_base._sprite.set_texture(preload("res://assets/textures/triggers/Alpha.svg"))
	_target = _base._target

func _update_target_link() -> void:
	_target_link._target = _base._target

func _start(_body: Node2D) -> void:
	if _easing._is_inactive():
		if _target != null:
			_initial_alpha = _target.modulate.a
		else:
			printerr("In ", name, ": _target is unset")

func _reset() -> void:
	if _target != null:
		_target.modulate.a = _initial_alpha
	else:
		printerr("In ", name, ": _target is unset")

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(_easing._weight):
		if _target != null:
			var _weight_delta = _easing._get_weight_delta()
			match _mode:
				Mode.SET:
					_target.modulate.a += (_alpha - _initial_alpha) * _weight_delta
				Mode.MULTIPLY:
					_target.modulate.a += (_alpha * _initial_alpha - _initial_alpha) * _weight_delta
				Mode.COPY:
					if _copy_target != null:
						_target.modulate.a = lerp(_initial_alpha, _copy_target.modulate.a * _copy_multiplier, _easing._weight)
					else:
						printerr("In ", name, ": copy_target is unset!")
		else:
			printerr("In ", name, ": _target is unset")
	elif Engine.is_editor_hint() or LevelManager.in_editor:
		_target_link.position = Vector2.ZERO
		if Engine.is_editor_hint(): _base.position = Vector2.ZERO
