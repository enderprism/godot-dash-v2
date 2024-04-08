@tool
extends Node2D
class_name tTimewarp


@export_range(0.0, 1.0 , 0.01, "or_greater") var _time_scale: float = 1.0

var _base: tBase
var _easing: tEasing
var _initial_time_scale: float
var _setup: tSetup

func _ready() -> void:
	_setup = tSetup.new(self, false)
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
