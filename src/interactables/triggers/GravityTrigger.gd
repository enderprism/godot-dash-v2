@tool
extends Node2D
class_name GravityTrigger

@export_range(0.0, 1.0 , 0.01, "or_greater") var gravity_multiplier: float = 1.0

var base: TriggerBase
var easing: EasingComponent

var _player: Player:
	get(): return LevelManager.player if not Engine.is_editor_hint() else null
var _initial_gravity_multiplier: float

func _ready() -> void:
	TriggerSetup.setup(self)
	base.sprite.set_texture(preload("res://assets/textures/triggers/Gravity.svg"))

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not easing.is_inactive() and easing.duration > 0.0:
		var _gravity_multiplier_delta: float = (gravity_multiplier - _initial_gravity_multiplier) * easing.weight_delta
		_player.gameplay_trigger_gravity_multiplier += _gravity_multiplier_delta
	if Engine.is_editor_hint():
		base.position = Vector2.ZERO

func start(_body: Node2D) -> void:
	_initial_gravity_multiplier = _player.gameplay_trigger_gravity_multiplier
	if easing.duration == 0.0:
		_player.gameplay_trigger_gravity_multiplier = gravity_multiplier

func reset() -> void:
	_player.gameplay_trigger_gravity_multiplier = _initial_gravity_multiplier
