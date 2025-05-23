@tool
extends Node2D
class_name TimewarpTrigger


@export_range(0.0, 1.0 , 0.01, "or_greater") var _time_scale: float = 1.0

var base: TriggerBase
var easing: TriggerEasing

var _initial_time_scale: float

func _ready() -> void:
	TriggerSetup.setup(self)
	base.sprite.set_texture(preload("res://assets/textures/triggers/Timewarp.svg"))

func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint() and not easing.is_inactive():
		if easing.duration > 0.0:
			var _time_scale_delta: float = (_time_scale - _initial_time_scale) * easing.weight_delta
			Engine.time_scale += _time_scale_delta
	if Engine.is_editor_hint():
		base.position = Vector2.ZERO

func start(_body: Node2D) -> void:
	_initial_time_scale = Engine.time_scale
	if easing.duration == 0.0:
		Engine.time_scale = _time_scale

func reset() -> void:
	Engine.time_scale = _initial_time_scale
