@tool
extends Node2D
class_name tGravity


@export_range(0.0, 1.0 , 0.01, "or_greater") var _gravity_multiplier: float = 1.0

var _player: Player
var _base: tBase
var _easing: tEasing
var _initial_gravity_multiplier: float
var _setup: tSetup

func _ready() -> void:
	_setup = tSetup.new(self, false)
	_base._sprite.set_texture(preload("res://assets/textures/triggers/Gravity.svg"))
	_player = LevelManager.player

func _start(_body: Node2D) -> void:
	_initial_gravity_multiplier = _player._gameplay_trigger_gravity_multiplier
	if _easing._duration == 0.0:
		_player._gameplay_trigger_gravity_multiplier = _gravity_multiplier

func _reset() -> void:
	_player._gravity_multiplier = _initial_gravity_multiplier

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not is_zero_approx(_easing._weight):
		if _easing._duration > 0.0:
			var _weight_delta: float = _easing._get_weight_delta()
			var _gravity_multiplier_delta: float = (_gravity_multiplier - _initial_gravity_multiplier) * _weight_delta
			_player._gameplay_trigger_gravity_multiplier += _gravity_multiplier_delta
	if Engine.is_editor_hint():
		_base.position = Vector2.ZERO
