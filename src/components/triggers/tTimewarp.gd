@tool
extends Node2D
class_name tTimewarp


@export_range(0.0, 1.0 , 0.01, "or_greater") var _time_scale: float = 1.0

var _base: tBase
var _easing: tEasing
var _initial_time_scale: float

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
	_base._sprite.set_texture(preload("res://assets/textures/triggers/Timewarp.svg"))

func _start(_body: Node2D) -> void:
	_initial_time_scale = Engine.time_scale
	if _easing._duration == 0.0:
		Engine.time_scale = _time_scale

func _reset() -> void:
	Engine.time_scale = _initial_time_scale

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(_easing._weight):
		if _easing._duration > 0.0:
			var _weight_delta: float = _easing._get_weight_delta()
			var _time_scale_delta: float = (_time_scale - _initial_time_scale) * _weight_delta
			Engine.time_scale += _time_scale_delta
	if Engine.is_editor_hint():
		_base.position = Vector2.ZERO
